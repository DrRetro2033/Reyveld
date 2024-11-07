import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ansix/ansix.dart';
import 'package:yaml/yaml.dart';
import 'package:lua_dardo/lua.dart';
import '../extensions.dart';
import '../arceus.dart';
import '../main.dart';
import '../cli.dart';
import '../version_control/constellation.dart';

enum AddonFeatureSets {
  none,
  patterns,
}

mixin Lua {
  /// # `LuaState` `_initLuaVM`
  /// ## Initializes a new Lua State.
  /// Returns the state, with the script loaded.
  LuaState _initLuaVM(
      String script, Map<String, int Function(LuaState)> dartFunctions) {
    // print(script);
    LuaState state = LuaState.newState();
    state.openLibs();
    for (String key in dartFunctions.keys) {
      state.register(key, dartFunctions[key]!);
    }
    state.doString(script);
    return state;
  }

  /// # `Map<String, dynamic>` read(String file)
  /// ## Gets the returned table of a function call.
  Map<String, dynamic> _getTableFromState(LuaState state) {
    Map<String, dynamic> resultTable = {};
    if (state.isTable(-1)) {
      state.pushNil();
      while (state.next(-2)) {
        String? key = state.toStr(-2);
        dynamic value;
        if (state.isString(-1)) {
          value = state.toStr(-1);
        } else if (state.isNumber(-1)) {
          value = state.toNumber(-1);
        } else if (state.isInteger(-1)) {
          value = state.toInteger(-1);
        } else if (state.isBoolean(-1)) {
          value = state.toBoolean(-1);
        } else if (state.isTable(-1)) {
          value = _getTableFromState(state);
        } else {
          value =
              state.typeName(state.type(-1)); // Fallback for unsupported types
        }
        try {
          int x = int.parse(value);
          value = x;
        } catch (e) {
          // Do nothing
        }
        resultTable[key!] = value;
        state.pop(1);
      }
    }
    return resultTable;
  }

  void call(LuaState state, String functionName,
      {List<dynamic> args = const []}) {
    state.getGlobal(functionName);
    for (dynamic arg in args) {
      if (arg is String) {
        state.pushString(arg);
      } else if (arg is int) {
        state.pushInteger(arg);
      } else if (arg is bool) {
        state.pushBoolean(arg);
      } else if (arg is double) {
        state.pushNumber(arg);
      } else {
        state.pushNil();
      }
    }
    state.pCall(args.length, 1, 0);
  }
}

/// # `class` `Addon`
/// ## The base class for all Addon projects.
abstract class Addon {
  String path;
  File get addonFile => File(path);
  String get decodedString {
    Uint8List data = addonFile.readAsBytesSync();
    List<int> decoded = gzip.decoder.convert(data.toList());
    return utf8.decode(decoded);
  }

  AddonDetails get details => _getDetails();
  Map<String, int Function(LuaState)> get dartFunctions;
  Addon(this.path);

  AddonDetails _getDetails() {
    return AddonDetails(
        loadYaml(decodedString.split("---END-OF-DETAILS---")[0]));
  }

  String _getCode() {
    return decodedString.split("---END-OF-DETAILS---")[1];
  }

  /// # `factory` `Addon.package()`
  /// ## Packages an addon project into a `*.arcaddon` file.
  /// Returns an `Addon` object.
  factory Addon.package(String pathToProject, String packageTo) {
    pathToProject = pathToProject.fixPath();
    Directory projectDirectory = Directory(pathToProject);
    if (!projectDirectory.existsSync()) {
      print("❌ Directory for packing was not found!");
      exit(1);
    }
    File addonDetailFile = File("$pathToProject/addon.yaml");
    if (!addonDetailFile.existsSync()) {
      print("❌ Addon YAML was not found!");
    }
    if (!Directory(packageTo).existsSync()) {
      throw Exception("❌ Directory for packing does not exist!");
    }

    AddonDetails details =
        AddonDetails(loadYaml(addonDetailFile.readAsStringSync()));

    if (!details.isVaild()) {
      throw Exception(
          "❌ Addon YAML is not valid! Not packaging addon until it is valid! Please read Arceus documentation for more information.");
    }

    String name = details.name.toLowerCase().replaceAll(' ', "_");
    final addonFilePath = "${packageTo.fixPath()}/$name.arcaddon";

    if (File(addonFilePath).existsSync()) {
      File(addonFilePath).deleteSync();
    }

    // Compile all Lua Scripts into a single file.
    String compiled = File("${projectDirectory.path}/${details.entrypoint}")
        .readAsStringSync();
    while (RegExp(r"require '(.*)'").firstMatch(compiled) != null) {
      RegExpMatch? element = RegExp(r"require '(.*)'").firstMatch(compiled)!;
      compiled = compiled.replaceRange(
        element.start,
        element.end,
        "",
      );
      File entity = projectDirectory.listSync(recursive: true).firstWhere(
              (e) => e is File && e.path.endsWith("${element.group(1)}.lua"))
          as File;
      compiled += "\n${entity.readAsStringSync()}";
    }

    // Replace hex values with their decimal value as lua_dardo does not support hex.
    while (RegExp(r"0x(\d|[A-F]|[a-f])*").firstMatch(compiled) != null) {
      RegExpMatch? match = RegExp(r"0x(\d|[A-F]|[a-f])*").firstMatch(compiled);
      compiled = compiled.replaceRange(match!.start, match.end,
          int.tryParse(match.group(0)!.substring(2), radix: 16).toString());
    }

    // Finally, combine it into a single file.
    File addonFile = File(addonFilePath);
    addonFile.createSync(recursive: true);
    addonFile.writeAsBytesSync(gzip.encoder.convert("""
    ${details.write()}
    $compiled
"""
        .codeUnits));

    return Addon.load(addonFilePath);
  }

  factory Addon.load(String pathToAddonFile) {
    if (!File(pathToAddonFile).existsSync()) {
      throw Exception("File not found: $pathToAddonFile");
    }

    Addon addon = TestAddon(pathToAddonFile);
    switch (addon.details.featureSet) {
      case AddonFeatureSets.patterns:
        return PatternAddon(pathToAddonFile);
      default:
        throw Exception("Unsupported feature set: ${addon.details.featureSet}");
    }
  }

  factory Addon.installGlobally(String pathToAddonFile,
      {bool deleteOld = true}) {
    if (!File(pathToAddonFile).existsSync()) {
      throw Exception("File not found: $pathToAddonFile");
    }
    File file = File(pathToAddonFile);
    Uint8List data = file.readAsBytesSync();
    if (deleteOld) {
      try {
        file.deleteSync();
      } catch (e) {
        print(
            "⚠️ Unable to delete old add-on file. Skipping step and continuing installation.");
      }
    }

    file = File("${Arceus.globalAddonPath}/${pathToAddonFile.getFilename()}");
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
    return Addon.load(
        "${Arceus.globalAddonPath}/${pathToAddonFile.getFilename()}");
  }

  factory Addon.installLocally(String pathToAddonFile,
      {bool deleteOld = true}) {
    if (!File(pathToAddonFile).existsSync()) {
      throw Exception("File not found: $pathToAddonFile");
    }
    File file = File(pathToAddonFile);
    Uint8List data = file.readAsBytesSync();
    if (deleteOld) {
      file.deleteSync();
    }
    file = File(
        "${Constellation(path: currentPath).addonFolderPath}/${pathToAddonFile.getFilename()}");
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
    return Addon.load(
        "${Constellation(path: currentPath).addonFolderPath}/${pathToAddonFile.getFilename()}");
  }

  static List<Addon> getInstalledAddons() {
    List<Addon> addons = <Addon>[];
    for (FileSystemEntity entity
        in Directory(Arceus.globalAddonPath).listSync()) {
      if (entity is File && entity.path.endsWith(".arcaddon")) {
        addons.add(Addon.load(entity.path));
      }
    }

    if (Constellation.checkForConstellation(currentPath)) {
      final constellation = Constellation(path: currentPath);
      for (FileSystemEntity entity in constellation.addonDirectory.listSync()) {
        if (entity is File && entity.path.endsWith(".arcaddon")) {
          addons.add(Addon.load(entity.path));
        }
      }
    }
    return addons;
  }

  /// # `bool` `validate()`
  /// ## Validates the addon, throwing an exception if it is invalid.
  /// Surround this function in a try/catch block.
  /// Must be implemented by subclasses.
  void vaildate();
}

/// # `class` `AddonDetails`
/// ## Contains the addon's details parsed from the `addon.yaml` file.
class AddonDetails {
  final YamlMap _details;
  AddonDetails(this._details);

  String get name => _details["name"].toString();
  String get description => _details["description"].toString();
  YamlList get authors => _details["authors"];
  String get version => _details["version"].toString();

  /// The Lua script where the required functions are located.
  /// For example, if the entrypoint is `main.lua`, then the script that will be loaded is `main.lua`.
  String get entrypoint => _details["entrypoint"].toString();

  AddonFeatureSets get featureSet => _getFeatureSet();
  Set<String> get permissions => _getPermissions();

  AddonFeatureSets _getFeatureSet() {
    String featureSet = _details["feature-set"];
    switch (featureSet) {
      case "pattern":
        return AddonFeatureSets.patterns;
      default:
        return AddonFeatureSets.none;
    }
  }

  Set<String> _getPermissions() {
    Set<String> permissions = {};
    switch (featureSet) {
      case AddonFeatureSets.patterns:
        permissions.addAll(["Reading & Writing Files."]);
        break;
      default:
        permissions.addAll(["None."]);
        break;
    }
    return permissions;
  }

  dynamic findProperty(String key) => _details[key];

  bool isVaild() {
    bool valid = true;
    if (!_hasName()) {
      print("❌ Addon YAML does not contain a name!");
      valid = false;
    }
    if (!_hasDescription()) {
      print("❌ Addon YAML does not contain a description!");
      valid = false;
    }
    if (!_hasAuthors()) {
      print("❌ Addon YAML does not contain any authors!");
      valid = false;
    }
    if (!_hasVersion()) {
      print("❌ Addon YAML does not contain a version!");
      valid = false;
    }
    if (!_hasEntrypoint()) {
      print("❌ Addon YAML does not contain an entrypoint!");
      valid = false;
    }
    if (!_hasFeatureSets()) {
      print("❌ Addon YAML does not contain any feature sets!");
      valid = false;
    }
    return valid;
  }

  bool _hasName() {
    return _details.containsKey("name");
  }

  bool _hasDescription() {
    return _details.containsKey("description");
  }

  bool _hasAuthors() {
    return _details.containsKey("authors") &&
        _details["authors"] is YamlList &&
        _details["authors"].length > 0;
  }

  bool _hasVersion() {
    return _details.containsKey("version") &&
        _details["version"] is String &&
        _details["version"].length > 0;
  }

  bool _hasEntrypoint() {
    return _details.containsKey("entrypoint") &&
        _details["entrypoint"] is String &&
        _details["entrypoint"].length > 0;
  }

  bool _hasFeatureSets() {
    return _details.containsKey("feature-set") &&
        _details["feature-set"] is String;
  }

  String write() {
    return """
${_details.toString()}
---END-OF-DETAILS---
""";
  }
}

/// # `class` `TestAddon`
/// ## An addon for testing purposes.
/// Used in the `load` function to make sure that the addon is not only valid, but to also get the details, without comitting to a specific subclass.
class TestAddon extends Addon {
  TestAddon(super.path);
  @override
  // TODO: implement dartFunctions
  Map<String, int Function(LuaState p1)> get dartFunctions =>
      throw UnimplementedError();

  @override
  void vaildate() {
    // TODO: implement vaildate
  }
}

/// # `class` `PatternAddon`
/// ## An addon that uses the `patterns` feature set.
/// The pattern feature set is used to read and write to files with a specific format.
/// It requires a `read` and `write` function.
class PatternAddon extends Addon with Lua {
  static const bool defaultIsLittleEndian = false;

  @override
  Map<String, int Function(LuaState)> get dartFunctions => {
        "ru8": readU8,
        "ru16": readU16,
        "ru32": readU32,
        "ru64": readU64,
        "rstr8": readString8,
        "rstr16": readString16,
        "rfield": readBitfield,
        "validate": validateTable
      };
  ByteData? data;

  PatternAddon(super.path);

  Map<String, dynamic> read(String file, {bool showResults = true}) {
    LuaState state = _initLuaVM(_getCode(), dartFunctions);
    data = File(file).readAsBytesSync().buffer.asByteData();
    call(state, "read", args: [file, file.getExtension()]);
    Map<String, dynamic> resultTable = _getTableFromState(state);
    if (resultTable.isEmpty && showResults) {
      print("❌ Failed to read data from $file");
    } else {
      print("✅ Read data from $file");
    }
    return resultTable;
  }

  @override
  void vaildate() {
    final script = _getCode();
    if (!script.contains("function read(filename)")) {
      throw Exception("Addon does not contain read function");
    }
    if (!script.contains("function write(filename, data)")) {
      throw Exception("Addon does not contain write function");
    }
  }

  factory PatternAddon.getAssoiatedAddon(String filename) {
    List<Addon> addons = Addon.getInstalledAddons();
    final patternAddons = addons.map((e) => e is PatternAddon ? e : null);
    for (PatternAddon? addon in patternAddons) {
      if (addon != null) {
        if (addon.details.findProperty("compatible-files") is YamlList) {
          YamlList compatibleFiles =
              addon.details.findProperty("compatible-files");
          if (compatibleFiles.any((e) => RegExp(e).hasMatch(filename))) {
            return addon;
          }
        }
      }
    }
    throw Exception("No patterns addon found!");
  }

  int _getAddressFromLua(LuaState state, {int idx = 1}) {
    int? address = 0;
    if (state.isString(idx)) {
      String? str = state.checkString(idx);
      // if (str!.startsWith("0x")) {
      //   str = str.substring(2);
      // }
      address = int.tryParse(str!);
    } else if (state.isInteger(idx)) {
      address = state.checkInteger(idx);
    }
    // state.pop(idx);
    if (address == null) {
      throw Exception("Invalid address!");
    }
    return address;
  }

  int readU8(LuaState state) {
    int address = _getAddressFromLua(state);
    state.pushInteger(data!.getUint8(address));
    return 1;
  }

  int readU16(LuaState state) {
    int address = _getAddressFromLua(state);
    bool isLittleEndian =
        state.isBoolean(2) ? state.toBoolean(2) : defaultIsLittleEndian;
    state.pushInteger(
        data!.getUint16(address, isLittleEndian ? Endian.little : Endian.big));
    return 1;
  }

  int readU32(LuaState state) {
    int address = _getAddressFromLua(state);
    bool isLittleEndian =
        state.isBoolean(2) ? state.toBoolean(2) : defaultIsLittleEndian;
    state.pushInteger(
        data!.getUint32(address, isLittleEndian ? Endian.little : Endian.big));
    return 1;
  }

  int readU64(LuaState state) {
    int address = _getAddressFromLua(state);
    bool isLittleEndian =
        state.isBoolean(2) ? state.toBoolean(2) : defaultIsLittleEndian;
    state.pushInteger(
        data!.getUint64(address, isLittleEndian ? Endian.little : Endian.big));
    return 1;
  }

  int readString8(LuaState state) {
    int address = _getAddressFromLua(state);
    int length = _getAddressFromLua(state);
    String string = utf8.decode(data!.buffer.asUint8List(address, length));
    state.pushString(string);
    return 1;
  }

  int readString16(LuaState state) {
    final address = _getAddressFromLua(state, idx: 1);
    int length = _getAddressFromLua(state, idx: 2);
    // length *= 2;
    String string = String.fromCharCodes(
        data!.buffer.asUint16List(address, length).toList());
    state.pushString(string);
    return 1;
  }

  int readBitfield(LuaState state) {
    bool reverse = false;
    if (state.getTop() == 3) {
      reverse = state.isBoolean(3) ? state.toBoolean(3) : false;
      state.pop(1);
    }
    int address = _getAddressFromLua(state);
    Map<String, dynamic> table = _getTableFromState(state);
    int size = 0;
    Map<String, int> sizedTable = {};
    for (String key in table.keys) {
      if (table[key] is Map<String, dynamic>) {
        Map<String, dynamic> subTable = table[key] as Map<String, dynamic>;
        sizedTable[subTable["1"]] = subTable[
            "2"]; // Done like this, so plug-in devlopers don't need to type a key for every bit chunk.

        size += sizedTable[subTable["1"]]!; // Move
      }
      // if (table[key] is int) {
      //   size += table[key] as int;
      //   sizedTable[key] = table[key] as int;
      // } else if (table[key] is String &&
      //     (table[key] as String).startsWith("pad")) {
      //   size += int.parse((table[key] as String).substring(3));
      //   sizedTable[key] = int.parse((table[key] as String).substring(3));
      // } else {
      //   try {
      //     sizedTable[key] = int.parse(table[key]);
      //     size += sizedTable[key] as int;
      //   } catch (e) {
      //     print(e);
      //   }
      //   continue;
      // }
    }
    int byteSize = (size / 8).ceil();
    BigInt combinedBitfield = BigInt.zero;
    List<int> bytes = data!.buffer.asUint8List(address, byteSize).toList();
    for (int i in (reverse ? bytes.reversed : bytes)) {
      combinedBitfield = (combinedBitfield << 8) | BigInt.from(i);
    }
    int offset = 0;
    Map<String, dynamic> finalTable = {};
    for (String key in sizedTable.keys) {
      finalTable[key] =
          _getValueInBitfield(combinedBitfield, offset, sizedTable[key] as int);
      offset += sizedTable[key] as int;
    }

    state.newTable();
    for (String key in finalTable.keys) {
      state.pushString(key);
      if (finalTable[key] is int) {
        state.pushInteger(finalTable[key]);
      } else if (finalTable[key] is bool) {
        state.pushBoolean(finalTable[key]);
      }
      state.setTable(-3);
    }
    return 1;
  }

  int validateTable(LuaState state) {
    Map<String, dynamic> table = _getTableFromState(state);
    state.pop(1);
    Map<String, dynamic> vaildationTable = _getTableFromState(state);
    try {
      final checkTable = _validateTable(vaildationTable, table);
      if (checkTable.isNotEmpty) {
        print("❌ Data Validation failed.");
        state.pushBoolean(false);
        print(AnsiTreeView(checkTable, theme: Cli.treeTheme));
      } else {
        print("✅ Data Validation passed.");
        state.pushBoolean(true);
      }
    } catch (e) {
      state.pushBoolean(false);
      print(e);
    }
    return 1;
  }

  Map<String, dynamic> _validateTable(
      Map<String, dynamic> vaildationTable, Map<String, dynamic> table) {
    Map<String, dynamic> checkTable = {};
    for (String key in table.keys) {
      if (vaildationTable.containsKey(key)) {
        if (vaildationTable[key] is int) {
          if (table[key] is String) {
            int maxLength = vaildationTable[key];
            if (table[key].length > maxLength) {
              checkTable[key] = false;
            }
          } else if (table[key] is int) {
            int maxValue = (1 << vaildationTable[key]) - 1;
            if (table[key] > maxValue || table[key] < 0) {
              checkTable[key] = false;
            }
          }
        } else if (vaildationTable[key] is Map<String, dynamic>) {
          final x = _validateTable(vaildationTable[key], table[key]);
          if (x.isNotEmpty) {
            checkTable[key] = x;
          }
        }
      }
    }
    return checkTable;
  }

  dynamic _getValueInBitfield(BigInt combinedNumber, int offset, int size) {
    BigInt value =
        ((combinedNumber >> offset) & ((BigInt.one << size) - BigInt.one));
    if (size == 1) {
      return value == BigInt.zero ? false : true;
    } else if (size > 1 && size <= 64) {
      return value.toInt();
    } else {
      throw Exception("Unsupported bitfield size: $size.");
    }
  }
}

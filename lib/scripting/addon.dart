import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:yaml/yaml.dart';

import './squirrel.dart';
import './feature_sets/feature_sets.dart';
import './squirrel_bindings_generated.dart';
import '../version_control/constellation.dart';
import '../extensions.dart';
import '../arceus.dart';

enum FeatureSets {
  none,
  pattern,
}

class Addon {
  final File addonFile;

  String get path => addonFile.path;
  String get name => getMetadata()["name"];

  bool get isGlobal {
    if (isUninstalled()) {
      throw Exception("Addon is not installed.");
    }

    if (Constellation.checkForConstellation(path)) {
      return false;
    }

    return true;
  }

  bool isUninstalled() => !addonFile.existsSync();

  late AddonContext _context;

  AddonContext get context {
    if (isUninstalled()) {
      throw Exception("Addon is not installed.");
    }
    return _context;
  }

  /// # `String` get code
  /// ## Returns the code of the addon.
  /// Used by context.
  String get code => getCode();

  String get decodedString {
    Uint8List data = addonFile.readAsBytesSync();
    List<int> decoded = gzip.decoder.convert(data.toList());
    return utf8.decode(decoded);
  }

  FeatureSets get featureSet {
    switch (getMetadata()["feature-set"]) {
      case "pattern":
        return FeatureSets.pattern;
      default:
        return FeatureSets.none;
    }
  }

  Addon(this.addonFile) {
    switch (featureSet) {
      case FeatureSets.pattern:
        _context = PatternAdddonContext(this);
        break;
      case FeatureSets.none:
        _context = NoneAdddonContext(this);
        break;
    }
  }

  static Addon package(String projectPath, String outputPath) {
    if (!_validate(projectPath)) {
      YamlMap yaml = _getAddonYaml(projectPath);

      String body = _getAddonYamlAsString(projectPath);
      body += "\n---END-OF-DETAILS---\n";
      String entrypoint = yaml["entrypoint"];
      body += File("$projectPath/$entrypoint").readAsStringSync();
      body += "\n";
      while (body.contains(RegExp(r"#\s*include\(([a-zA-Z\/\s]*.nut)\s*\)"))) {
        final match =
            RegExp(r"#\s*include\(([a-zA-Z\/\s]*.nut)\s*\)").firstMatch(body)!;
        body.replaceRange(match.start, match.end, "");
        body += File("$projectPath/${match.group(1)!}").readAsStringSync();
        body += "\n";
      }
      final ctx = NoneAdddonContext();
      if (!ctx.hasRequiredFunctions(body)) {
        throw Exception(
          "Required functions are missing! Please check your addon.yaml file. Required functions: ${ctx.requiredFunctions.join(", ")}",
        );
      }

      Uint8List bytes = utf8.encode(body);
      List<int> compressed = gzip.encoder.convert(bytes);
      File("$outputPath/${(yaml["name"] as String).toLowerCase().replaceAll(" ", "_")}.arcaddon")
          .writeAsBytesSync(compressed);

      return Addon(File(
          "$outputPath/${(yaml["name"] as String).toLowerCase().replaceAll(" ", "_")}.arcaddon"));
    }
    throw Exception("Invalid addon! Please check your addon.yaml file.");
  }

  /// # `YamlMap` _getAddonYaml(`String` projectPath)
  /// ## Returns the contents of addon.yaml as a YamlMap.
  ///
  /// The `projectPath` argument is the path to the project directory.
  static YamlMap _getAddonYaml(String projectPath) {
    return loadYaml(File("$projectPath/addon.yaml").readAsStringSync());
  }

  static String _getAddonYamlAsString(String projectPath) {
    return File("$projectPath/addon.yaml").readAsStringSync();
  }

  static bool _validate(String projectPath) {
    bool isValid = true;

    if (!File("$projectPath/addon.yaml").existsSync()) {
      isValid = false;
    }

    YamlMap addonYaml =
        loadYaml(File("$projectPath/addon.yaml").readAsStringSync());

    if (!_validateMetadata(addonYaml)) {
      // do check on metadata to make sure it is valid.
      isValid = false;
    }
    return isValid;
  }

  static bool _validateMetadata(YamlMap metadata) {
    bool isVaild = true;

    // check for required keys
    List<String> requiredKeys = [
      "name",
      "description",
      "version",
      "authors",
      "feature-set",
      "entrypoint"
    ];

    for (String key in requiredKeys) {
      if (!metadata.containsKey(key)) {
        isVaild = false;
      }
    }

    if (isVaild) {
      // check typing of values
      if (metadata["name"] is! String) {
        isVaild = false;
      } else if (metadata["description"] is! String) {
        isVaild = false;
      } else if (metadata["version"] is! String) {
        isVaild = false;
      } else if (metadata["authors"] is! YamlList) {
        isVaild = false;
      } else if (metadata["feature-set"] is! String) {
        isVaild = false;
      } else if (metadata["entrypoint"] is! YamlList) {
        isVaild = false;
      }
    }

    return isVaild;
  }

  /// # `factory` Addon.installGlobally()
  /// ## Installs an addon globally.
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
        if (!Arceus.isInternal) {
          print(
              "⚠️ Unable to delete old add-on file. Skipping step and continuing installation.");
        }
      }
    }

    file = File("${Arceus.globalAddonPath}/${pathToAddonFile.getFilename()}");
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
    return Addon(
        File("${Arceus.globalAddonPath}/${pathToAddonFile.getFilename()}"));
  }

  /// # `factory` Addon.installLocally()
  /// ## Installs an addon locally to the current constellation.
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
        "${Constellation(path: Arceus.currentPath).addonFolderPath}/${pathToAddonFile.getFilename()}");
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
    return Addon(File(
        "${Constellation(path: Arceus.currentPath).addonFolderPath}/${pathToAddonFile.getFilename()}"));
  }

  static bool uninstallByName(String name) {
    for (Addon addon in getInstalledAddons()) {
      if (addon.name == name) {
        addon.uninstall();
        return true;
      }
    }
    return false;
  }

  void uninstall() {
    File file = File(path);
    file.deleteSync();
  }

  /// # `static` getInstalledAddons()
  /// ## Returns a list of all installed addons.
  static List<Addon> getInstalledAddons() {
    List<Addon> addons = <Addon>[];
    if (Constellation.checkForConstellation(Arceus.currentPath)) {
      final constellation = Constellation(path: Arceus.currentPath);
      if (!constellation.addonDirectory.existsSync()) {
        constellation.addonDirectory.createSync();
      }
      for (FileSystemEntity entity in constellation.addonDirectory.listSync()) {
        if (entity is File && entity.path.endsWith(".arcaddon")) {
          addons.add(Addon(File(entity.path)));
        }
      }
    }
    for (FileSystemEntity entity
        in Directory(Arceus.globalAddonPath).listSync()) {
      if (entity is File && entity.path.endsWith(".arcaddon")) {
        addons.add(Addon(File(entity.path)));
      }
    }
    return addons;
  }

  static List<Addon> getInstalledAddonsByFeatureSet(FeatureSets featureSet) {
    List<Addon> addons = <Addon>[];
    for (Addon addon in getInstalledAddons()) {
      if (addon.featureSet == featureSet) {
        addons.add(addon);
      }
    }
    return addons;
  }

  /// # `AddonDetails` _getDetails()
  /// ## Returns the details of the addon.
  /// It is separated by `---END-OF-DETAILS---`.
  YamlMap getMetadata() {
    return loadYaml(decodedString.split("---END-OF-DETAILS---")[0]);
  }

  /// # `String` _getCode()
  /// ## Returns the code of the addon.
  /// It is separated by `---END-OF-DETAILS---`.
  String getCode() {
    return decodedString.split("---END-OF-DETAILS---")[1];
  }
}

/// # `AddonContext`
/// ## An abstract class that represents the context of an addon.
/// Acts as the bridge between the addon and the Squirrel VM.
/// Before, Addon was abstract with subclasses acting as different feature sets.
/// However, this is not the case anymore. Addons will create a [AddonContext] that the `addon.yaml` asks for,
/// and then use it to run the addon.
abstract class AddonContext {
  static final RegExp functionNameRegex =
      RegExp(r"function\s([A-Za-z\d]*)\([A-Za-z,\s]*\)");

  List<String> get requiredFunctions => [];

  List<SquirrelFunction> get functions;

  Addon? addon;

  AddonContext([this.addon]) {
    Squirrel.init("C:/Repos/arceus");
  }

  bool hasRequiredFunctions(String code) {
    final matches = functionNameRegex.allMatches(code);
    for (String requiredFunction in requiredFunctions) {
      if (!matches.any((match) => match.group(1) == requiredFunction)) {
        return false;
      }
    }
    return true;
  }

  /// # `Pointer<SQVM>` startVM()
  /// ## Starts the Squirrel VM and returns the VM pointer.
  /// It also creates the API for the Squirrel VM, so be sure all the functions have been added to [functions].
  Pointer<SQVM> startVM() {
    final vm = Squirrel.run(addon!.code);
    Squirrel.createAPI(vm, functions);
    return vm;
  }
}

class NoneAdddonContext extends AddonContext {
  @override
  List<SquirrelFunction> get functions => [];

  NoneAdddonContext([super.addon]) : super();
}

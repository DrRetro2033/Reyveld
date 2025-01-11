import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cli_spin/cli_spin.dart';
import 'package:yaml/yaml.dart';

import 'package:arceus/scripting/squirrel.dart';
import 'package:arceus/scripting/feature_sets/feature_sets.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/arceus.dart';

enum FeatureSets {
  none,
  pattern,
}

class Addon {
  final File addonFile;

  Addon(this.addonFile) {
    if (!addonFile.existsSync()) {
      throw Exception("Addon file does not exist.");
    }
    switch (featureSet) {
      case FeatureSets.pattern:
        _context = PatternAddonContext(this);
        break;
      case FeatureSets.none:
        _context = NoneAdddonContext(this);
        break;
    }
  }

  String get path => addonFile.path;
  String get name => getMetadata()["name"] ?? "Unknown";

  bool get isGlobal {
    if (isUninstalled()) {
      throw Exception("Addon is not installed.");
    }

    if (Constellation.exists(path)) {
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

  String get code => getCode();

  String get decodedString {
    try {
      Uint8List data = addonFile.readAsBytesSync();
      List<int> decoded = gzip.decoder.convert(data.toList());
      return utf8.decode(decoded);
    } catch (e) {
      throw Exception("Failed to decode addon file: $e");
    }
  }

  FeatureSets get featureSet {
    switch (getMetadata()["feature-set"]) {
      case "pattern":
        return FeatureSets.pattern;
      default:
        return FeatureSets.none;
    }
  }

  void testRun(File testFile) {
    final yaml = loadYaml(testFile.readAsStringSync()) as YamlMap;
    _context.test(yaml);
  }

  static Addon package(String projectPath, String outputPath) {
    if (_validate(projectPath.fixPath())) {
      YamlMap yaml = _getAddonYaml(projectPath);

      String body = _getAddonYamlAsString(projectPath);
      body += "\n---END-OF-DETAILS---\n";
      String entrypoint = yaml["entrypoint"];
      String code = File("$projectPath/$entrypoint").readAsStringSync();
      List<String> includes = [entrypoint];
      while (RegExp(r"#\s*include\(([a-zA-Z\/\s]*.nut)\s*\)").hasMatch(code)) {
        code += "\n\n";
        final match =
            RegExp(r"#\s*include\(([a-zA-Z\/\s]*.nut)\s*\)").firstMatch(code)!;
        code = code.replaceRange(match.start, match.end, "");
        if (includes.contains(match.group(1)!)) {
          continue;
        }
        final file = File("$projectPath/${match.group(1)!}");
        if (!file.existsSync()) {
          throw Exception("Included file does not exist: ${match.group(1)}");
        }
        includes.add(match.group(1)!);
        code += file.readAsStringSync();
      }
      AddonContext ctx = NoneAdddonContext();
      switch (yaml["feature-set"]) {
        case "pattern":
          ctx = PatternAddonContext();
          break;
        default:
          break;
      }
      if (!ctx.hasRequiredFunctions(body)) {
        throw Exception(
          "Required functions are missing! Please check your addon.yaml file. Required functions: ${ctx.requiredFunctions.join(", ")}",
        );
      }

      Uint8List bytes = utf8.encode("$body$code");
      List<int> compressed = gzip.encoder.convert(bytes);
      File("$outputPath/${(yaml["name"] as String).toLowerCase().replaceAll(" ", "_")}.arcaddon")
          .writeAsBytesSync(compressed);

      return Addon(File(
          "$outputPath/${(yaml["name"] as String).toLowerCase().replaceAll(" ", "_")}.arcaddon"));
    }
    throw Exception("Invalid addon! Please check your addon.yaml file.");
  }

  static YamlMap _getAddonYaml(String projectPath) {
    try {
      return loadYaml(File("$projectPath/addon.yaml").readAsStringSync());
    } catch (e) {
      throw Exception("Failed to load addon.yaml: $e");
    }
  }

  static String _getAddonYamlAsString(String projectPath) {
    try {
      return File("$projectPath/addon.yaml").readAsStringSync();
    } catch (e) {
      throw Exception("Failed to read addon.yaml: $e");
    }
  }

  static bool _validate(String projectPath) {
    bool isValid = true;

    if (!File("$projectPath/addon.yaml").existsSync()) {
      isValid = false;
    }

    YamlMap addonYaml;
    try {
      addonYaml = loadYaml(File("$projectPath/addon.yaml").readAsStringSync());
    } catch (e) {
      return false;
    }

    if (!_validateMetadata(addonYaml)) {
      isValid = false;
    }
    return isValid;
  }

  static bool _validateMetadata(YamlMap metadata) {
    bool isValid = true;

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
        isValid = false;
      }
    }

    if (isValid) {
      if (metadata["name"] is! String ||
          metadata["description"] is! String ||
          metadata["version"] is! String ||
          metadata["authors"] is! YamlList ||
          metadata["feature-set"] is! String ||
          metadata["entrypoint"] is! String) {
        isValid = false;
      }
    }

    return isValid;
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

  factory Addon.installLocally(String pathToAddonFile,
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
        throw Exception("Failed to delete old addon file: $e");
      }
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
    try {
      File file = File(path);
      file.deleteSync();
    } catch (e) {
      throw Exception("Failed to uninstall addon: $e");
    }
  }

  static List<Addon> getInstalledAddons() {
    List<Addon> addons = <Addon>[];
    if (Constellation.exists(Arceus.currentPath)) {
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

  static List<Addon> getAddonsByFeatureSet(FeatureSets featureSet) {
    List<Addon> addons = <Addon>[];
    for (Addon addon in getInstalledAddons()) {
      if (addon.featureSet == featureSet) {
        addons.add(addon);
      }
    }
    return addons;
  }

  YamlMap getMetadata() {
    try {
      return loadYaml(decodedString.split("---END-OF-DETAILS---")[0]);
    } catch (e) {
      throw Exception("Failed to get metadata: $e");
    }
  }

  String getCode() {
    try {
      // print(decodedString.split("---END-OF-DETAILS---")[1]);
      return decodedString.split("---END-OF-DETAILS---")[1];
    } catch (e) {
      throw Exception("Failed to get code: $e");
    }
  }
}

abstract class AddonContext {
  static final RegExp functionNameRegex =
      RegExp(r"function\s([A-Za-z\d]*)\([A-Za-z,\s]*\)");

  List<String> get requiredFunctions => [];

  List<SquirrelFunction> get functions;

  Map<String, List<String>> get enums => {};

  Addon? addon;

  void test(YamlMap yaml);

  AddonContext([this.addon]) {
    Squirrel.loadSquirrelLibs("C:/Repos/arceus");
  }

  bool hasRequiredFunctions(String code) {
    final matches = functionNameRegex.allMatches(code);
    requiredFunctions
        .any((element) => !matches.any((m) => m.group(1) == element));
    return true;
  }

  Future<void> memCheck({int retries = 1024}) async {
    final spinner =
        CliSpin(text: " Testing memory...", spinner: CliSpinners.moon).start();
    for (int repeat = 1; repeat <= retries; repeat++) {
      spinner.text = " Testing memory... ($repeat/$retries)";
      try {
        final vm = startVM();
        vm.dispose();
      } catch (e) {
        spinner.fail(" Memory test failed ($repeat/$retries) 🚫");
        rethrow;
      }
      await Future.delayed(const Duration(microseconds: 1));
    }
    spinner.success(" Memory test passed! 🎉");
  }

  Squirrel startVM() {
    String additionalCode = _buildEnums();
    final vm = Squirrel(additionalCode + addon!.code);
    vm.createAPI(functions);
    return vm;
  }

  String _buildEnums() {
    String result = "";
    for (String key in enums.keys) {
      result += """
enum $key {
  ${enums[key]!.join(",\n  ")}
};
""";
    }
    return result;
  }
}

class NoneAdddonContext extends AddonContext {
  @override
  List<SquirrelFunction> get functions => [];

  @override
  void test(YamlMap yaml) {
    return;
  }

  NoneAdddonContext([super.addon]) : super();
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:yaml/yaml.dart';
import '../version_control/constellation.dart';

class AddOn {
  /// The path to the project folder. Does not need to be defined for already compiled addons.
  String? projectPath;

  /// The path to the addon file. Is required for both compilation and runtime.
  String? addonName;

  final Constellation _constellation;
  final Compiler _compiler = Compiler();

  File get addonFile =>
      File('${_constellation.addonFolderPath}/${addonName!}.evc');

  AddOn(this._constellation, {this.addonName, this.projectPath});

  void compile() {
    if (projectPath == null) {
      throw Exception(
          "Cannot compile without a project path specified, silly!");
    }

    final dir = Directory(projectPath!);
    Map<String, Map<String, String>> packages = {"project": {}};
    final files = dir
        .listSync(recursive: true)
        .where((element) => element.path.endsWith('.dart'))
        .map((e) => e.path)
        .toList(); // Get all the dart files.

    AddOnFingerprint y;
    if (!dir
        .listSync()
        .map((e) => e.path)
        .toList()
        .any((e) => e.endsWith('addon.yaml') || e.endsWith('addon.yml'))) {
      throw Exception(
          "Cannot compile without an addon.yaml file in the project folder.");
    } else {
      File addonYaml = File('$projectPath/addon.yaml');
      if (!addonYaml.existsSync()) {
        addonYaml = File('$projectPath/addon.yml');
      }
      final addonYamlMap = loadYaml(addonYaml.readAsStringSync());
      addonName = addonYamlMap['name'];
      y = AddOnFingerprint.fromYaml(addonYamlMap);
    }

    if (!files.any((e) => e.endsWith('main.dart'))) {
      throw Exception(
          "Cannot compile without a main.dart file in the project folder with read, write, and isCompatible functions.");
    } else {
      final mainCode = File("$projectPath/main.dart").readAsStringSync();
      if (!mainCode.contains("Map<String, dynamic> read(String file)") ||
          !mainCode
              .contains("void write(String file, Map<String, dynamic> data)") ||
          !mainCode.contains("bool isCompatible(String file)")) {
        throw Exception(
            "Cannot compile without a read, write, and or isCompatible function in the main.dart file.");
      }
    }

    for (var file in files) {
      final code = File(file).readAsStringSync(); // Read the file.
      packages["project"]?[file] =
          _changesImportsRelative(code); // Add the file to the package.
    }

    final addon = _compiler.compile(packages); // The compiled code.
    addonFile.createSync(
        recursive: true); // Create the compiled file for writing to.

    addonFile.writeAsBytesSync(y.fingerprint.codeUnits, mode: FileMode.write);

    addonFile.writeAsBytesSync(addon.write(),
        mode: FileMode.append); // Write the compiled addon to disk.
  }

  dynamic read(String file) {
    final runtime = Runtime(bytecode.buffer.asByteData());
    return runtime.executeLib("project", "read", [$String(file)]);
  }

  void write(String file, Map<String, dynamic> dataMap) {
    final runtime = Runtime(bytecode.buffer.asByteData());
    runtime.executeLib("project", "write", [$String(file), $Map.wrap(dataMap)]);
  }

  String _changesImportsRelative(String code) {
    final regex = RegExp(r"import '(.*)';");
    final matches = regex.allMatches(code);
    for (var match in matches) {
      final path = match.group(1)!;
      final newPath = "package:project/$path.dart";
      code.replaceRange(match.start, match.end, "import '$newPath';");
    }
    return code;
  }

  Uint8List get bytecode {
    final data = addonFile.readAsBytesSync();
    List<String> lines =
        utf8.decode(data.toList(), allowMalformed: true).split("\n");
    List<String> fingerprintLines = [];
    while (lines[0] != "<END_OF_FINGERPRINT>") {
      fingerprintLines.add(lines.removeAt(0));
    }
    lines.removeAt(0);
    return data.sublist(utf8.encode("${fingerprintLines.join("\n")}\n").length +
        utf8.encode("<END_OF_FINGERPRINT>\n").length);
  }

  AddOnFingerprint get fingerprint {
    final data = addonFile.readAsBytesSync();
    List<String> lines =
        utf8.decode(data.toList(), allowMalformed: true).split("\n");
    List<String> fingerprintLines = [];
    while (lines[0] != "<END_OF_FINGERPRINT>") {
      fingerprintLines.add(lines.removeAt(0));
    }
    return AddOnFingerprint.fromLines(fingerprintLines);
  }

  bool isCompatible(String file) {
    final bytecode = addonFile.readAsBytesSync().buffer.asByteData();
    final runtime = Runtime(bytecode);
    return runtime.executeLib("project", "isCompatible", [$String(file)]);
  }

  void printFingerprint() {
    print(fingerprint);
  }
}

class AddOnFingerprint {
  final String name;
  final String author;
  final String version;
  final String description;
  final YamlList compatibleFiles;

  AddOnFingerprint(this.name, this.author, this.version, this.description,
      this.compatibleFiles);

  String get fingerprint {
    String x = '$name\n$author\n$version\n$description\n';
    for (var file in compatibleFiles) {
      x += '$file\n';
    }
    x += "<END_OF_FINGERPRINT>\n";
    return x;
  }

  factory AddOnFingerprint.fromYaml(YamlMap yaml) {
    return AddOnFingerprint(yaml['name'], yaml['author'], yaml['version'],
        yaml['description'], yaml['compatible-files']);
  }

  factory AddOnFingerprint.fromLines(List<String> lines) {
    return AddOnFingerprint(lines[0], lines[1], lines[2], lines[3],
        YamlList.wrap(lines.sublist(4)));
  }

  @override
  String toString() {
    return "Name: $name\nAuthor: $author\nVersion: $version\nDescription: $description\nCompatible Files: $compatibleFiles";
  }
}

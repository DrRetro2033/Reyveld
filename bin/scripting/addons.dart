import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

class AddOn {
  /// The path to the project folder. Does not need to be defined for already compiled addons.
  String? projectPath;

  /// The path to the addon file. Is required for both compilation and runtime.
  String addonPath;
  final Compiler _compiler = Compiler();

  File get addonFile => File(addonPath);

  AddOn(this.addonPath, {this.projectPath});

  void compile() {
    if (projectPath == null) {
      throw Exception(
          "Cannot compile without a project path specified, silly!");
    }

    final dir = Directory(projectPath!);
    Map<String, Map<String, String>> packages = {"project": {}};
    final files = dir
        .listSync()
        .where((element) => element.path.endsWith('.dart'))
        .map((e) => e.path.split('/').last)
        .toList(); // Get all the dart files.

    if (!files.contains("main.dart")) {
      throw Exception(
          "Cannot compile without a main.dart file in the project folder with read and write functions.");
    } else {
      final mainCode = File("$projectPath/main.dart").readAsStringSync();
      if (!mainCode.contains("Map<String, dynamic> read(String file)") ||
          !mainCode.contains(
              "Map<String, dynamic> write(String file, Map<String, dynamic> dataMap)") ||
          !mainCode.contains("bool isCompatible(String file)")) {
        throw Exception(
            "Cannot compile without a read, write, and or isCompatible function in the main.dart file.");
      }
    }

    for (var file in files) {
      final code = File(file).readAsStringSync(); // Read the file.
      packages["project"]?[file] = code; // Add the file to the package.
    }

    final addon = _compiler.compile(packages); // The compiled code.
    addonFile.createSync(
        recursive: true); // Create the compiled file for writing to.
    addonFile
        .writeAsBytesSync(addon.write()); // Write the compiled addon to disk.
  }

  dynamic read(String file) {
    final bytecode = addonFile.readAsBytesSync().buffer.asByteData();
    final runtime = Runtime(bytecode);
    return runtime.executeLib("project", "read", [$String(file)]);
  }

  void write(String file, Map<String, dynamic> dataMap) {
    final bytecode = addonFile.readAsBytesSync().buffer.asByteData();
    final runtime = Runtime(bytecode);
    runtime.executeLib("project", "write", [$String(file), $Map.wrap(dataMap)]);
  }

  bool isCompatible(String file) {
    final bytecode = addonFile.readAsBytesSync().buffer.asByteData();
    final runtime = Runtime(bytecode);
    return runtime.executeLib("project", "isCompatible", [$String(file)]);
  }
}

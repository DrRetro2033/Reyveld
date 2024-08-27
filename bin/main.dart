import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:args/command_runner.dart";
import 'package:cli_spin/cli_spin.dart';
import 'file_pattern.dart';
import "version_control.dart";

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.
Future<dynamic> main(List<String> arguments) async {
  var runner = CommandRunner('arceus', "The ultimate save manager.");
  runner.addCommand(ConstellationCommands());
  runner.addCommand(PatternCommands());
  if (arguments.isNotEmpty) {
    return await runner.run(arguments);
  }
}

class ConstellationCommands extends Command {
  @override
  String get name => "const";
  @override
  String get description => "Commands for Constellations.";

  ConstellationCommands() {
    addSubcommand(CreateConstellationCommand());
    addSubcommand(ShowMapConstellationCommand());
    addSubcommand(CheckForDifferencesCommand());
    addSubcommand(BuildStarFileCommand());
  }
}

class CreateConstellationCommand extends Command {
  @override
  String get description =>
      "Creates a new constellation at a given, or current, path.";

  @override
  String get name => "create";

  CreateConstellationCommand() {
    argParser.addOption("path", abbr: "p", defaultsTo: Directory.current.path);
    argParser.addOption("name", abbr: "n");
  }

  @override
  void run() {
    Constellation(argResults?["path"], name: argResults?["name"]);
  }
}

class ShowMapConstellationCommand extends Command {
  @override
  String get description => "Shows the map of a constellation.";

  @override
  String get name => "map";

  ShowMapConstellationCommand() {
    argParser.addOption("path", abbr: "p", defaultsTo: Directory.current.path);
  }

  @override
  void run() {
    Constellation(argResults?["path"]).showMap();
  }
}

class CheckForDifferencesCommand extends Command {
  @override
  String get description =>
      "Checks for differences between a star and the current file.";

  @override
  String get name => "check";

  CheckForDifferencesCommand() {
    argParser.addOption("path", abbr: "p", defaultsTo: Directory.current.path);
    argParser.addOption("star", abbr: "s");
  }

  @override
  Future<bool> run() async {
    Constellation constellation = Constellation(argResults?["path"]);
    final spinner = CliSpin(
            text:
                "Checking for differences between current directory and provided star...")
        .start();
    String? hash;
    if (argResults?["star"] == null) {
      hash = constellation.currentStarHash;
    } else {
      hash = argResults?["star"];
    }
    bool result = Star(constellation, hash: hash).checkForDifferences();
    if (!result) {
      spinner.success("No differences found.");
    } else {
      spinner.fail("Differences found.");
    }
    return result;
  }
}

class BuildStarFileCommand extends Command {
  @override
  String get description =>
      "Gets a file from the constellation from a specific point in time.";

  @override
  String get name => "file";

  BuildStarFileCommand() {
    argParser.addOption("path", abbr: "p", defaultsTo: Directory.current.path);
    argParser.addOption("star", abbr: "s");
    argParser.addOption("file", abbr: "f", defaultsTo: Directory.current.path);
  }

  @override
  Future<Uint8List> run() async {
    Constellation constellation = Constellation(argResults?["path"]);
    Uint8List result = Star(constellation, hash: argResults?["star"])
        .buildFile(argResults?["file"])
        .data;
    return result;
  }
}

class PatternCommands extends Command {
  @override
  String get name => "pattern";
  @override
  String get description => "Commands for patterns.";

  PatternCommands() {
    addSubcommand(ReadPatternCommand());
  }
}

class ReadPatternCommand extends Command {
  @override
  String get description => "Read a file using a pattern.";

  @override
  String get name => "read";

  ReadPatternCommand() {
    argParser.addOption("pattern",
        abbr: "p", defaultsTo: Directory.current.path);
    argParser.addOption("file", abbr: "f", defaultsTo: Directory.current.path);
  }

  @override
  Future<String> run() async {
    return jsonEncode(
        FilePattern(argResults?["pattern"]).read(File(argResults?["file"])));
  }
}

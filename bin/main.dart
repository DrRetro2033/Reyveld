import 'dart:convert';
import 'dart:io';

import "package:args/command_runner.dart";
import 'arceus.dart';
import 'file_pattern.dart';
import "version_control.dart";

var arceus = Arceus();

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
    return jsonEncode(FilePattern(argResults?["pattern"]).read(File(argResults?["file"])));
  }
}

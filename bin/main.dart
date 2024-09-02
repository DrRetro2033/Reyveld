import 'dart:convert';
import 'dart:io';

// import 'package:ansix/ansix.dart';
import "package:args/command_runner.dart";
import 'package:cli_spin/cli_spin.dart';
import 'file_pattern.dart';
import "version_control/constellation.dart";

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.
Future<dynamic> main(List<String> arguments) async {
  // AnsiX.ensureSupportsAnsi();
  var runner = CommandRunner('arceus', "The ultimate save manager.");
  runner.argParser.addOption(
    "app-path",
    abbr: "a",
    defaultsTo: Directory.current.path,
  );
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
    addSubcommand(ConstellationJumpToCommand());
    addSubcommand(ConstellationBranchCommand());
  }
}

class CreateConstellationCommand extends Command {
  @override
  String get description =>
      "Creates a new constellation at a given, or current, path.";

  @override
  String get name => "create";

  CreateConstellationCommand() {
    argParser.addOption("path", abbr: "p", mandatory: true);
    argParser.addOption("name", abbr: "n", mandatory: true);
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
    argParser.addOption("path", abbr: "p", mandatory: true);
  }

  @override
  void run() {
    Constellation(argResults?["path"]).starmap.showMap();
  }
}

class CheckForDifferencesCommand extends Command {
  @override
  String get description =>
      "Checks for differences between a star and the current file.";

  @override
  String get name => "check";

  CheckForDifferencesCommand() {
    argParser.addOption("path", abbr: "p", mandatory: true);
    argParser.addOption("star", abbr: "s");
  }

  @override
  Future<bool> run() async {
    Constellation constellation = Constellation(argResults?["path"]);
    final spinner = CliSpin(
            text:
                "Checking for differences between current directory and provided star...")
        .start();
    bool result = constellation.checkForDifferences(argResults?["star"]);
    if (!result) {
      spinner.success("No differences found.");
    } else {
      spinner.fail("Differences found.");
    }
    return result;
  }
}

class ConstellationJumpToCommand extends Command {
  @override
  String get description =>
      "Jumps to a star in the constellation. Must call extract if you want the star to be extracted.";

  @override
  String get name => "jump";

  ConstellationJumpToCommand() {
    argParser.addOption("path", abbr: "p", mandatory: true);
    argParser.addOption("star", abbr: "s", mandatory: true);
  }

  @override
  void run() {
    Constellation(argResults?["path"]).starmap[argResults?["star"]];
  }
}

class ConstellationBranchCommand extends Command {
  @override
  String get description =>
      "Creates a new branch in the constellation from the current star.";
  @override
  String get name => "branch";

  ConstellationBranchCommand() {
    argParser.addOption("path", abbr: "p", mandatory: true);
    argParser.addOption("name", abbr: "n", mandatory: true);
  }

  @override
  void run() {
    Constellation(argResults?["path"]).branch(argResults?["name"]);
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
  dynamic run() {
    return FilePattern(argResults?["pattern"])
        .read(File(argResults?["file"]).readAsBytesSync());
  }
}

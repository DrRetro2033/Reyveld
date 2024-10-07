import 'dart:io';
import 'dart:convert';
import "package:args/command_runner.dart";
import 'package:cli_spin/cli_spin.dart';
import 'file_pattern.dart';
import 'extensions.dart';
import "version_control/constellation.dart";

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.

late String currentPath;

Future<dynamic> main(List<String> arguments) async {
  // AnsiX.ensureSupportsAnsi();
  var runner = CommandRunner('arceus', "The ultimate save manager.");
  runner.argParser.addOption(
    "app-path",
    abbr: "a",
    defaultsTo: Directory.current.path,
  );
  currentPath = Directory.current.path;
  if (arguments.contains("--app-path") || arguments.contains("-a")) {
    currentPath = arguments[
        arguments.indexWhere((e) => e == "--app-path" || e == "-a") + 1];
  }
  if (!Constellation.checkForConstellation(currentPath)) {
    runner.addCommand(CreateConstellationCommand());
  } else {
    runner.addCommand(ShowMapConstellationCommand());
    runner.addCommand(CheckForDifferencesCommand());
    runner.addCommand(ConstellationJumpToCommand());
    runner.addCommand(ConstellationGrowCommand());
    runner.addCommand(ConstellationDeleteCommand());
  }
  runner.addCommand(ReadPatternCommand());
  runner.addCommand(WritePatternCommand());

  if (arguments.isNotEmpty) {
    return await runner.run(arguments);
  }
}

class CreateConstellationCommand extends Command {
  @override
  String get description =>
      "Creates a new constellation at a given, or current, path.";

  @override
  String get name => "create";

  CreateConstellationCommand() {
    argParser.addOption("name", abbr: "n", mandatory: true);
    argParser.addMultiOption("user", abbr: "u", defaultsTo: Iterable.empty());
  }

  @override
  void run() {
    List<String>? users = argResults?["user"];
    if (users?.isEmpty ?? true) {
      Constellation(currentPath, name: argResults?["name"]);
    } else {
      Constellation(currentPath, name: argResults?["name"], users: users!);
    }
  }
}

class ShowMapConstellationCommand extends Command {
  @override
  String get description => "Get the map of a constellation.";

  @override
  String get name => "map";

  ShowMapConstellationCommand();

  @override
  dynamic run() {
    Constellation constellation = Constellation(currentPath);
    constellation.starmap?.showMap();
    return jsonEncode(constellation.starmap?.toJson());
  }
}

class CheckForDifferencesCommand extends Command {
  @override
  String get description =>
      "Checks for differences between the current star and what is currently in the directory.";

  @override
  String get name => "check";

  CheckForDifferencesCommand() {
    argParser.addOption("star", abbr: "s");
  }

  @override
  Future<bool> run() async {
    Constellation constellation = Constellation(currentPath);
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
  String get description => "Jumps to a different star in the constellation.";

  @override
  String get name => "jump";

  ConstellationJumpToCommand() {
    argParser.addOption("star", abbr: "s", mandatory: true);
  }

  @override
  void run() {
    Constellation(currentPath).starmap?[argResults?["star"]];
  }
}

class ConstellationGrowCommand extends Command {
  @override
  String get description =>
      "Continues the from the current star to a new star in the constellation. Will branch if necessary.";
  @override
  String get name => "grow";

  ConstellationGrowCommand() {
    argParser.addOption("name", abbr: "n", mandatory: true);
  }

  @override
  void run() {
    Constellation(currentPath).grow(argResults?["name"]);
  }
}

class ConstellationDeleteCommand extends Command {
  @override
  String get description => "Deletes the constellation. Be CAREFUL!";

  @override
  String get name => "delete";

  @override
  void run() {
    Constellation(currentPath).delete();
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
    String json = jsonEncode(
        FilePattern(argResults!.option("pattern")!.fixPath()).read(
            File(argResults!.option("file")!.fixPath()).readAsBytesSync()));
    print(json);
    return json;
  }
}

class WritePatternCommand extends Command {
  @override
  String get description => "Write a file using a pattern.";

  @override
  String get name => "write";

  WritePatternCommand() {
    argParser.addOption("data", abbr: "d", mandatory: true);
    argParser.addOption("pattern",
        abbr: "p", defaultsTo: Directory.current.path);
    argParser.addOption("file", abbr: "f", defaultsTo: Directory.current.path);
  }

  @override
  dynamic run() {
    FilePattern(argResults!.option("pattern")!.fixPath()).write(
        File(argResults!.option("file")!.fixPath()),
        jsonDecode(argResults!.option("data")!));
  }
}

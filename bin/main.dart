import 'dart:io';
import 'dart:convert';
// import 'package:ansix/ansix.dart';
import "package:args/command_runner.dart";
import 'file_pattern.dart';
import 'extensions.dart';

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
  runner.addCommand(PatternCommands());
  currentPath = runner.argParser.parse(arguments)["app-path"];
  if (arguments.isNotEmpty) {
    return await runner.run(arguments);
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

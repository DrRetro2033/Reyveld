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
  runner.addCommand(OpenCommand());
  if (arguments.isNotEmpty) {
    return await runner.run(arguments);
  }
}

class OpenCommand extends Command {
  @override
  String get description => "Open a Planet.";

  @override
  String get name => "open";

  OpenCommand() {
    argParser.addOption("path", abbr: "p");
  }

  @override
  void run() {
    Planet(argResults?["path"]);
  }
}

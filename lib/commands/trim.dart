import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:args/command_runner.dart';
import 'package:arceus/arceus.dart';
import 'package:cli_spin/cli_spin.dart';

class TrimCommand extends Command {
  @override
  String get name => "trim";

  @override
  String get description => "Trim/Delete data in Arceus.";

  TrimCommand() {
    addSubcommand(TrimConstCommand());
  }
}

class TrimConstCommand extends Command {
  @override
  String get name => "const";

  @override
  String get description => "Delete a constellation in Arceus.";

  TrimConstCommand() {
    argParser.addOption("const",
        abbr: "c",
        help: "The name of the constellation you wish to delete.",
        mandatory: true);
  }

  @override
  Future<void> run() async {
    String constellationName = findOption("const");
    final kit = File("${Arceus.constFolderPath}/$constellationName.skit");
    if (!await kit.exists()) {
      throw FileSystemException(
          "Cannot find skit with the name of $constellationName.",
          "${Arceus.constFolderPath}/$constellationName.skit");
    }
    final spinner = CliSpin(
            text: "Deleting $constellationName...", spinner: CliSpinners.moon)
        .start();

    await kit.delete();
    spinner.success("Deleted $constellationName!");
    return;
  }
}

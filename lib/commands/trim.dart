import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:args/command_runner.dart';
import 'package:arceus/arceus.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:interact/interact.dart';

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
        abbr: "c", help: "The name of the constellation you wish to delete.");
  }

  @override
  Future<void> run() async {
    String constellationName;
    if (argResults!.option("const") == null) {
      final consts =
          Directory(Arceus.constFolderPath).listSync(recursive: true);
      if (consts.isEmpty) {
        throw Exception("No constellations found.");
      }
      final selection = Select(
          prompt: "Select constellation to delete.",
          options: [
            ...consts.map((e) => e.path.getFilename(withExtension: false)),
            "Cancel"
          ]).interact();
      if (selection == consts.length) {
        return;
      }
      constellationName =
          consts[selection].path.getFilename(withExtension: false);
    } else {
      constellationName = argResults!.option("const")!;
    }
    final spinner = CliSpin(
            text: "Deleting $constellationName...", spinner: CliSpinners.moon)
        .start();
    final kit = File("${Arceus.constFolderPath}/$constellationName.skit");
    await kit.delete();
    spinner.success("Deleted $constellationName!");
    return;
  }
}

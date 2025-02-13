import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/version_control/constellation.dart';
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
    addSubcommand(TrimStarCommand());
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

class TrimStarCommand extends Command {
  @override
  String get name => "star";

  @override
  // TODO: implement description
  String get description => "Trim a star from a constellation";

  TrimStarCommand() {
    argParser.addOption("const",
        abbr: 'c',
        mandatory: true,
        help: "The constellation you wish to trim.");
  }

  @override
  Future<void> run() async {
    String constName = findOption("const");
    final kit = SKit("${Arceus.constFolderPath}/$constName.skit");
    CliSpin spinner =
        CliSpin(text: "Checking for changes...", spinner: CliSpinners.moon)
            .start();
    final constellation = await kit.getConstellation();
    if (await constellation!.checkForChanges()) {
      spinner.warn("There are changes in the constellation.");
      final confirm = Confirm(
              prompt: "Are you sure you want to trim the current star?",
              defaultValue: false)
          .interact();
      if (!confirm) {
        return;
      }
    }
    final star = constellation.getCurrentStar();
    spinner = CliSpin(text: "Trimming...", spinner: CliSpinners.moon).start();
    if (star.isRoot) {
      spinner.fail("Cannot trim root star!");
      return;
    }
    await star.trim();
    await kit.save();
    spinner.success("Deleted '${star.name}'!");
  }
}

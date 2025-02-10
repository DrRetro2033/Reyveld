import 'package:arceus/arceus.dart';
import 'package:arceus/main.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:args/command_runner.dart';

import 'package:cli_spin/cli_spin.dart';
import 'package:interact/interact.dart';

class JumpCommand extends Command with GetRest {
  @override
  String get name => "jump";

  @override
  String get description => """
jump to a different star in a constellation. Will check for changes in the tracked folder.
""";

  @override
  String get summary => "Jump to a different star in a constellation.";

  JumpCommand() {
    argParser.addOption("const",
        abbr: "c", help: "The constellation to jump in.", mandatory: true);
  }

  @override
  Future<void> run() async {
    final commands = getRest("Enter the star to jump to.");
    CliSpin spinner = CliSpin(
            text: "Attempting jump to $commands...", spinner: CliSpinners.moon)
        .start();
    final kit = SKit("${Arceus.constFolderPath}/${argResults?["const"]}.skit");
    final constellation = await kit.getConstellation();
    final archive = await constellation!.getCurrentStar().archive;
    if (await archive!.checkForChanges(constellation.path)) {
      spinner.warn("There are changes in the tracked folder. ");
      final confirm = Confirm(
              prompt:
                  "Do you want to overwrite the changes in the tracked folder?",
              defaultValue: false)
          .interact();
      if (!confirm) {
        return;
      }
      spinner = CliSpin(
              text: "Overwriting changes in the tracked folder...",
              spinner: CliSpinners.moon)
          .start();
    }
    constellation.getStarAt(commands).makeCurrent();
    await archive.extract(constellation.path);
    await kit.save();
    spinner.success("Jumped to ${constellation.getCurrentStar().name}!");
  }
}

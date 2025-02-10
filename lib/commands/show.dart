import 'package:arceus/arceus.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:arceus/extensions.dart';

class ShowCommand extends Command {
  @override
  String get name => "show";

  @override
  String get description => "Display a entity in Arceus in a readable format.";

  ShowCommand() {
    addSubcommand(ShowConstellationCommand());
  }
}

class ShowConstellationCommand extends Command {
  @override
  String get name => "const";

  @override
  String get description => "Display a constellation as a tree.";

  ShowConstellationCommand() {
    argParser.addOption("const",
        abbr: "c", help: "The constellation to display.", mandatory: true);
  }

  @override
  Future<void> run() async {
    final constName = findOption("const");
    final kit = SKit("${Arceus.constFolderPath}/$constName.skit");
    final spinner =
        CliSpin(text: "Loading...", spinner: CliSpinners.moon).start();
    final constellation = await kit.getConstellation();
    spinner.stop();
    constellation!.printTree();
  }
}

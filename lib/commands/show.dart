import 'package:arceus/arceus.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/version_control/star.dart';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:arceus/extensions.dart';

class ShowCommand extends Command {
  @override
  String get name => "show";

  @override
  String get description => "Display an entity in Arceus in a readable format.";

  ShowCommand() {
    addSubcommand(ShowConstellationCommand());
    addSubcommand(ShowSKitCommand());
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
    final constName = findOption("const").fixFilename();
    final kit = await SKit.open(
        "${Arceus.constFolderPath}/$constName.skit", SKitType.constellation);
    final spinner =
        CliSpin(text: "Loading...", spinner: CliSpinners.moon).start();
    final constellation = await kit.getConstellation();
    spinner.stop();
    constellation!.printDetails<Star>();
  }
}

class ShowSKitCommand extends Command {
  @override
  String get name => "skit";

  @override
  String get description => "Display a skit in a readable format.";

  @override
  bool get hidden => true;

  ShowSKitCommand() {
    argParser.addOption("skit",
        abbr: "s", help: "The skit to display.", mandatory: true);
  }

  @override
  Future<void> run() async {
    final kitName = findOption("skit").fixPath();
    final kit = SKit(kitName);
    if (!await kit.exists()) {
      print("Kit does not exist!");
      return;
    }
    await kit.printDetails();
  }
}

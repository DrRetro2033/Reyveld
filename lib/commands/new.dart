import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/skit/skit.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:arceus/main.dart';
import 'package:interact/interact.dart';

class NewCommand extends Command {
  @override
  String get name => "new";

  @override
  String get description => "Create a new entity in Arceus.";

  NewCommand() {
    addSubcommand(NewConstellationCommand());
    addSubcommand(NewStarCommand());
    addSubcommand(NewAddonCommand());
  }
}

class NewConstellationCommand extends Command with GetRest {
  @override
  String get name => "const";

  @override
  String get description => "Create a new constellation in Arceus.";

  NewConstellationCommand() {
    argParser.addOption("path",
        abbr: "p", help: "The path to track.", mandatory: true);
  }

  @override
  Future<void> run() async {
    String name = getRest("Enter a name for the constellation.");
    if (!await Directory(argResults?["path"]).exists()) {
      throw Exception("${argResults?["path"]} does not exist.");
    }
    final kit = SKit("${Arceus.constFolderPath}/${name.fixFilename()}.skit");
    final spinner = CliSpin(
            text: "Checking if constellation exists...",
            spinner: CliSpinners.moon)
        .start();
    if (await kit.exists()) {
      spinner.fail(
          "Constellation already exists! Either delete it or choose a different name.");
      return;
    }
    final header = await kit.create(type: SKitType.constellation);
    spinner.text = "Creating constellation...";
    final constellation = await ConstellationCreator(
            name, (argResults?["path"] as String).fixPath())
        .create(kit);
    spinner.text = "Creating initial star...";
    await constellation.createRootStar();
    header.addChild(constellation);
    spinner.text = "Saving...";
    await kit.save();
    spinner.success("Finished creating '$name'!");
  }
}

class NewStarCommand extends Command with GetRest {
  @override
  String get name => "star";

  @override
  String get description => "Create a new star from the current star.";

  NewStarCommand() {
    argParser.addOption("const",
        abbr: "c",
        help: "The constellation to create the star in.",
        mandatory: true);
  }

  @override
  Future<void> run() async {
    String constName = findOption("const").fixFilename();
    final kit = await SKit.open(
        "${Arceus.constFolderPath}/$constName.skit", SKitType.constellation);
    String name = getRest("Enter a name for the new star.");
    CliSpin spinner =
        CliSpin(text: "Checking for changes...", spinner: CliSpinners.moon)
            .start();
    final constellation = await kit.getConstellation();
    if (!await constellation!.checkForChanges()) {
      spinner.warn("There are no changes in the constellation.");
      final confirm = Confirm(
              prompt: "Are you sure you want to create a new star?",
              defaultValue: false)
          .interact();
      if (!confirm) {
        return;
      }
    }
    spinner =
        CliSpin(text: "Creating '$name'...", spinner: CliSpinners.moon).start();
    final star = await constellation.getCurrentStar().grow(name);
    await kit.save();
    spinner.success("Created '${star.name}'!");
  }
}

class NewAddonCommand extends Command {
  @override
  String get name => "addon";

  @override
  String get description => "Create a new addon from a project folder.";

  NewAddonCommand() {
    argParser.addOption('path', abbr: 'p', mandatory: true);
  }

  @override
  Future<void> run() async {
    String path = argResults!.option("path")!;
    if (!await Directory(path).exists()) {
      print("Directory does not exist!");
    }
  }
}

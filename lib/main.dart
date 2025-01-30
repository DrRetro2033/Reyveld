import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import "package:arceus/serekit/serekit.dart";
import 'package:arceus/version_control/constellation.dart';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:interact/interact.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner("arceus", "Arceus CLI program");
  runner.addCommand(NewCommand());
  runner.addCommand(ShowCommand());
  await runner.run(args);
}

mixin GetRest on Command {
  String getRest(String fallbackPrompt) {
    String? value;
    if (!hasRest) {
      value =
          Input(prompt: fallbackPrompt, validator: (value) => value.isNotEmpty)
              .interact();
    }
    value ??= argResults?.rest.join(" ") ?? "";
    return value;
  }

  bool get hasRest => argResults?.rest.isNotEmpty ?? false;
}

class NewCommand extends Command {
  @override
  String get name => "new";

  @override
  String get description => "Create a new entity in Arceus.";

  NewCommand() {
    addSubcommand(NewConstellationCommand());
    addSubcommand(NewStarCommand());
  }
}

class NewConstellationCommand extends Command with GetRest {
  @override
  String get name => "const";

  @override
  String get description => "Create a new constellation in Arceus.";

  NewConstellationCommand() {
    argParser.addOption("path",
        abbr: "n", help: "The path to track.", mandatory: true);
  }

  @override
  Future<void> run() async {
    String name = getRest("Enter a name for the constellation.");
    if (!await Directory(argResults?["path"]).exists()) {
      throw Exception("Path does not exist.");
    }
    final spinner =
        CliSpin(text: "Creating SERE kit...", spinner: CliSpinners.moon)
            .start();
    final kit = SKit("${Arceus.constFolderPath}/$name.skit");
    final header = await kit.create(type: SKitType.constellation);
    spinner.text = "Creating constellation...";
    final constellation = await ConstFactory().create(
        kit, {"name": name, "path": (argResults?["path"] as String).fixPath()});
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
    String name = getRest("Enter a name for the new star.");
    final kit = SKit("${Arceus.constFolderPath}/${argResults?["const"]}.skit");
    final header = await kit.getKitHeader();
    final constellation = header.getChild<Constellation>();
    final star = await constellation!.getCurrentStar().grow(name);
    print("Created '${star.name}'!");
    await kit.save();
  }
}

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
    final spinner =
        CliSpin(text: "Loading...", spinner: CliSpinners.moon).start();
    final kit = SKit("${Arceus.constFolderPath}/${argResults?["const"]}.skit");
    final header = await kit.getKitHeader();
    final constellation = header.getChild<Constellation>();
    spinner.stop();
    constellation!.printTree();
  }
}

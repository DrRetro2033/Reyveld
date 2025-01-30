import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import "package:arceus/serekit/serekit.dart";
import 'package:arceus/version_control/constellation.dart';
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner("arceus", "Arceus CLI program");
  runner.addCommand(NewConstellationCommand());
  await runner.run(args);
}

mixin GetRest on Command {
  String getRest() {
    return argResults?.rest.join(" ") ?? "";
  }

  bool get hasRest => argResults?.rest.isNotEmpty ?? false;
}

class NewConstellationCommand extends Command with GetRest {
  @override
  String get name => "new";

  @override
  String get description => "Create a new constellation.";

  NewConstellationCommand() {
    argParser.addOption("path",
        abbr: "n", help: "The path to track.", mandatory: true);
  }

  @override
  Future<void> run() async {
    String? name;
    if (!hasRest) {
      name = Input(
          prompt: "Name of the new constellation: ",
          validator: (value) => value.isNotEmpty).interact();
    }
    name ??= getRest();
    if (!await Directory(argResults?["path"]).exists()) {
      throw Exception("Path does not exist.");
    }
    final kit = SKit("${Arceus.constFolderPath}/$name.skit");
    final header = await kit.create(type: SKitType.constellation);
    final constellation = await ConstFactory().create(
        kit, {"name": name, "path": (argResults?["path"] as String).fixPath()});
    await constellation.createRootStar();
    header.addChild(constellation);
    await kit.save();
  }
}

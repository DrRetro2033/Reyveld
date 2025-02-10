import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/serekit/sobjects/settings.dart';
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:arceus/commands/commands.dart';

ArceusSettings? settings;

Future<void> main(List<String> args) async {
  final runner = CommandRunner("arceus", "Arceus CLI program");
  runner.argParser.addOption("const", abbr: "c", hide: true);
  runner.addCommand(NewCommand());
  runner.addCommand(ShowCommand());
  runner.addCommand(JumpCommand());
  runner.addCommand(TestCommand());
  runner.addCommand(TrimCommand());
  runner.addCommand(SettingsCommand());

  /// Gets the current settings from the settings kit.
  settings = (await (await Arceus.getSettingKit()).getKitHeader())
      .getChild<ArceusSettings>();

  await runner.run(args);
  exit(0);
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

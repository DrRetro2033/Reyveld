import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobjects/settings.dart';
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:arceus/commands/commands.dart';

ArceusSettings? settings;

Future<void> main(List<String> args) async {
  final runner = CommandRunner("arceus", "Arceus CLI program");
  runner.argParser.addOption("const", abbr: "c", hide: true);
  runner.argParser.addOption("skit", abbr: "s", hide: true);
  runner.addCommand(NewCommand());
  runner.addCommand(ShowCommand());
  runner.addCommand(JumpCommand());
  runner.addCommand(TestCommand());
  runner.addCommand(TrimCommand());
  runner.addCommand(SettingsCommand());

  /// Gets the current settings from the settings kit.
  settings = (await (await Arceus.getSettingKit()).getHeader())!
      .getChild<ArceusSettings>();
  try {
    await runner.run(args);
  } catch (e, st) {
    print("""

Whoops! It looks like something went wrong! For more details, open the following log file:
${Arceus.mostRecentLog.path}

If the error persists, please open an issue on GitHub and provide the log above. 
Your feedback is much appreciated!
""");
    Arceus.talker.critical("Crash Handler", e, st);
  }

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

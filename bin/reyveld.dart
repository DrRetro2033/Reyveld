import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:reyveld/commands/commands.dart';
import 'package:reyveld/reyveld.dart';

/// Entry point for the Reyveld CLI.
Future<void> main(List<String> args) async {
  final runner = CommandRunner("reyveld", """
A multi-purpose toolbox for working with files, with a focus on simplicity and ease of use.
""")
    ..addCommand(RunCommand())
    ..addCommand(StartCommand());
  runner.argParser
      .addFlag("verbose", abbr: "v", help: "Run Reyveld in verbose mode.");
  final results = runner.parse(args);
  Reyveld.verbose = results.flag("verbose");
  if (await Reyveld.getOtherOption("DISABLE_WELCOME_MESSAGE") != "True") {
    Reyveld.printToConsole("""
Dear user/developer,
  Thank you for using Reyveld! ❤️

  Reyveld is a passion project created by me to make a diverse set of tools for working with files.
As someone who has been making random scripts to read Pokémon files, resize textures for Titanfall 2, 
and sift through Source Engine demo files; I wanted a toolbox that didn't need a bunch of boilerplate code,
or multiple dependencies to get started. That's why Reyveld is only a single executable! It's all under one 
roof, and it's easy to use! No more installing Python or Java just to do a simple task!

  Reyveld will always be free and open source, however, if you want to support me to continue developing Reyveld, 
consider sponsoring me on GitHub. Every single dollar is appreciated!

  If you do not know what you are doing, you can read more about Reyveld here: 
https://github.com/DrRetro2033/Reyveld.

  If you have any problems, questions, or suggestions; Please feel free to open an issue on GitHub: 
https://github.com/DrRetro2033/Reyveld/issues/new.

  If you want to support the development of Reyveld, you can consider sponsoring me on GitHub: 
https://github.com/sponsors/DrRetro2033.

Sincerely,
DrRetro2033 - Creator of Reyveld.

P.S. If you want to disable this message, you can go to ${Reyveld.appDataPath}/config.ini and set 
"DISABLE_WELCOME_MESSAGE" to "1", in the "other" section.
"""
        .orange);
  }
  await runner.run(args);
}

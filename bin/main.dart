import 'dart:convert';
import 'dart:io';

import "package:args/command_runner.dart";
import 'arceus.dart';
import 'file_pattern.dart';

var arceus = Arceus();

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.
Future<dynamic> main(List<String> arguments) async {
  var runner = CommandRunner('arceus', "The ultimate save manager.");
  runner.addCommand(GamesCommand());
  runner.addCommand(UniverseCommand());
  runner.addCommand(PatternCommand());
  if (arguments.isNotEmpty) {
    return await runner.run(arguments);
  }
}

class GamesCommand extends Command {
  @override
  final name = "games";
  @override
  final description = "Manage your games.";

  GamesCommand() {
    addSubcommand(ListGamesCommand());
    addSubcommand(AddGameCommand());
    addSubcommand(RemoveGameCommand());
  }
}

class AddGameCommand extends Command {
  @override
  final name = "add";
  @override
  final description = "Add a new game.";

  AddGameCommand() {
    argParser.addOption("name");
    argParser.addOption("path");
  }

  @override
  void run() {
    arceus.addGame(
        argResults!.option("name") ?? "", argResults!.option("path") ?? "");
  }
}

class ListGamesCommand extends Command {
  @override
  final name = "list";
  @override
  final description = "List all games.";

  @override
  void run() {
    arceus.printGames();
  }
}

class RemoveGameCommand extends Command {
  @override
  final name = "remove";
  @override
  final description = "Remove a game.";
}

class UniverseCommand extends Command {
  @override
  final name = "universe";
  @override
  final description = "Manage a game's universe.";

  UniverseCommand() {
    addSubcommand(CreateUniverseCommand());
    addSubcommand(JumpToUniverseCommand());
    addSubcommand(ListUniversesCommand());
  }
}

/// # `class` CreateUniverseCommand extends Command
/// ## Create a new point in time in a universe.
class CreateUniverseCommand extends Command {
  @override
  final name = "create";
  @override
  final description = "Create a new universe.";
}

/// #  `class` JumpToUniverseCommand extends Command
/// ## Jump to a specific point in time.
class JumpToUniverseCommand extends Command {
  @override
  final name = "jump";
  @override
  final description = "Jump to a specific point in time.";
}

/// # `class` ListUniversesCommand extends Command
/// ## List all universes.
/// Uses AnsiX for printing tree views.
class ListUniversesCommand extends Command {
  @override
  final name = "list";
  @override
  final description = "List all universes.";

  ListUniversesCommand() {
    argParser.addOption("game", help: "The hash of the game you want to list.");
  }

  @override
  void run() {
    if (argResults!.wasParsed("game")) {
      arceus.getGame(argResults!.option("game")!).then(
        (game) async {
          await game.printIndex();
        },
      );
    }
  }
}

class PatternCommand extends Command {
  @override
  final name = "pattern";
  @override
  final description = "Use patterns to parse data.";

  PatternCommand() {
    addSubcommand(ParsePatternCommand());
  }
}

class ParsePatternCommand extends Command {
  @override
  final name = "parse";
  @override
  final description = "Parse a file with a pattern to get data.";

  ParsePatternCommand() {
    argParser.addOption("file");
    argParser.addOption("pattern");
  }

  @override
  dynamic run() {
    if (argResults!.wasParsed("file") && argResults!.wasParsed("pattern")) {
      final file = File(arceus.fixPath(argResults!.option("file")!));
      final pattern = FilePattern(argResults!.option("pattern")!);
      return jsonEncode(pattern.read(file));
    }
  }
}

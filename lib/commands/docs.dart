import 'package:args/command_runner.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/scripting/interfaces.dart';
import 'package:reyveld/scripting/lua.dart';

class DocsCommand extends Command {
  @override
  String get name => 'docs';

  @override
  String get description => 'Find out how to use Reyveld and its API.';

  DocsCommand() {
    addSubcommand(MakeCommand());
    addSubcommand(TypesCommand());
  }
}

class MakeCommand extends Command {
  @override
  String get name => 'make';

  @override
  String get description => 'Generates the Lua API documentation for Reyveld.';

  @override
  Future<void> run() async {
    final spinner = CliSpin(spinner: CliSpinners.bounce)
        .start("Generating Docs...".skyBlue);

    /// Regenerate the lua documentation.
    await Lua.generateDocs().listen((doc) {
      spinner.text = "Generating $doc...".skyBlue;
    }, onError: (e) => Reyveld.talker.error(e)).asFuture();

    spinner.success(
        "Generated Lua Docs at \"${Reyveld.appDataPath}/docs/${Reyveld.version.toString()}/\""
            .skyBlue);
  }
}

class TypesCommand extends Command {
  @override
  String get name => 'types';

  @override
  String get description => 'Lists all of the types of objects in Reyveld.';

  @override
  Future<void> run() async => Reyveld.printToConsole(interfaces
      .map((e) =>
          "${e.className.paleTurquoise} ${e.ancestors.map((e) => "${'← '.paleGreen}${e.className} ").join()}")
      .join("\n")
      .toString());
}

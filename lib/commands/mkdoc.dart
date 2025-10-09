import 'package:args/command_runner.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/scripting/lua.dart';

class DocRegenCommand extends Command {
  @override
  String get name => 'mkdoc';

  @override
  String get description => 'Regenerates the documentation.';

  @override
  Future<void> run() async {
    final spinner = CliSpin(spinner: CliSpinners.bounce)
        .start("Generating Docs...".skyBlue);

    /// Regenerate the lua documentation.
    await Lua.generateDocs().listen((doc) {
      spinner.text = "Generating $doc...".skyBlue;
    }).asFuture();

    spinner.success(
        "Generated Lua Docs at \"${Reyveld.appDataPath}/docs/${Reyveld.version.toString()}/\""
            .skyBlue);
  }
}

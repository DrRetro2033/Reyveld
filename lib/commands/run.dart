import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:reyveld/event.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/security/authveld.dart';

class RunCommand extends Command {
  @override
  final name = "run";
  @override
  final description = "Run a lua script.";

  RunCommand() {
    argParser.addOption('file', help: 'The file to run.', abbr: 'f');
    argParser.addOption('token',
        help: 'The AuthVeld certificate token to use.', abbr: 't');
  }

  @override
  Future<void> run() async {
    final script = argResults!.option("file");
    final scriptCertificate =
        await AuthVeld.getContract(argResults!.option("token") ?? "");

    if (script != null) {
      final file = File(script);
      if (!await file.exists()) {
        Reyveld.printToConsole("❌ File '$script' does not exist. Exiting.".red);
        exit(1);
      }
      final content = await file.readAsString();
      try {
        final r = await Lua(contract: scriptCertificate).run(content);
        Reyveld.printToConsole(SocketEvent.completed(r.result));
        exit(0);
      } catch (e, st) {
        Reyveld.printToConsole(SocketEvent.error(e));
        Reyveld.talker.error("Error running script", e, st);
        exit(1);
      }
    }
  }
}

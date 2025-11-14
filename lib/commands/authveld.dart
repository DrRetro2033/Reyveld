import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/security/authveld.dart';

class AuthVeldCommand extends Command {
  @override
  final name = "authveld";

  @override
  final description = "AuthVeld commands.";

  AuthVeldCommand() {
    addSubcommand(AuthVeldShowCertCommand());
    addSubcommand(AuthVeldDeauthorizeCommand());
    addSubcommand(AuthVeldAuthorizeCommand());
  }
}

class AuthVeldShowCertCommand extends Command {
  @override
  final name = "contracts";

  @override
  final description =
      "Show all of the contracts currently registered with AuthVeld.";

  AuthVeldShowCertCommand();

  @override
  Future<void> run() async {
    await AuthVeld.getContracts().then((certs) {
      for (final cert in certs) {
        Reyveld.printToConsole(cert.toDisplayString());
      }
    });
  }
}

class AuthVeldDeauthorizeCommand extends Command {
  @override
  final name = "deauthorize";

  @override
  final description = "Deauthorize a contract by its token.";

  AuthVeldDeauthorizeCommand() {
    argParser.addOption("token", abbr: "t");
  }

  @override
  Future<void> run() async {
    final spinner =
        CliSpin(spinner: CliSpinners.bounce).start("Deauthorizing...");
    await AuthVeld.deauthorizeContract(argResults!.option("token")!);
    spinner.success("Deauthorization complete.");
  }
}

class AuthVeldAuthorizeCommand extends Command {
  @override
  final name = "reauthorize";

  @override
  final description = "Reauthorize a contract by its token.";

  AuthVeldAuthorizeCommand() {
    argParser.addOption("token", abbr: "t");
  }

  @override
  Future<void> run() async {
    final spinner =
        CliSpin(spinner: CliSpinners.bounce).start("Reauthorizing...");
    await AuthVeld.authorizeContract(argResults!.option("token")!);
    spinner.success("Reauthorization complete.");
  }
}

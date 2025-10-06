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
  final name = "show-certs";

  @override
  final description = "Show all of the current certificates.";

  AuthVeldShowCertCommand();

  @override
  Future<void> run() async {
    await AuthVeld.getCertificates().then((certs) {
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
  final description = "Deauthorize a certificate by its token.";

  AuthVeldDeauthorizeCommand() {
    argParser.addOption("token", abbr: "t");
  }

  @override
  Future<void> run() async {
    final spinner =
        CliSpin(spinner: CliSpinners.bounce).start("Deauthorizing...");
    await AuthVeld.deauthorize(argResults!.option("token")!);
    spinner.success("Deauthorization complete.");
  }
}

class AuthVeldAuthorizeCommand extends Command {
  @override
  final name = "reauthorize";

  @override
  final description = "Reauthorize a certificate by its token.";

  AuthVeldAuthorizeCommand() {
    argParser.addOption("token", abbr: "t");
  }

  @override
  Future<void> run() async {
    final spinner =
        CliSpin(spinner: CliSpinners.bounce).start("Reauthorizing...");
    await AuthVeld.authorize(argResults!.option("token")!);
    spinner.success("Reauthorization complete.");
  }
}

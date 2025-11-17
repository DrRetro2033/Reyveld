import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/security/authveld.dart';
import 'package:reyveld/security/contract/contract.dart' show SContract;
import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/server.dart' as server;

class AuthVeldCommand extends Command {
  @override
  final name = "authveld";

  @override
  final description = "Interact with AuthVeld to modifiy and view contracts.";

  AuthVeldCommand() {
    addSubcommand(AuthVeldShowCertCommand());
    addSubcommand(AuthVeldDeauthorizeCommand());
    addSubcommand(AuthVeldAuthorizeCommand());
    addSubcommand(AuthVeldNewCommand());
    addSubcommand(AuthVeldClearCommand());
  }
}

class AuthVeldShowCertCommand extends Command {
  @override
  final name = "list";

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

class AuthVeldClearCommand extends Command {
  @override
  final name = "clear";

  @override
  final description = "Clear all of the contracts from AuthVeld.";

  @override
  Future<void> run() async {
    final spinner = CliSpin(spinner: CliSpinners.bounce).start("Clearing...");
    await AuthVeld.clearContracts();
    spinner.success("Contracts cleared.");
  }
}

class AuthVeldNewCommand extends Command {
  @override
  final name = "new";

  @override
  final description = "Create a new contract from a YAML file.";

  AuthVeldNewCommand() {
    argParser.addOption("file", abbr: "f");
  }

  @override
  Future<void> run() async {
    if (argResults!.option("file") == null) return;
    await server.runServer();
    final spinner = CliSpin(spinner: CliSpinners.bounce)
        .start("Creating new contract...".skyBlue);
    final file = File(argResults!.option("file")!);
    if (!await file.exists()) {
      spinner.fail("File '${argResults!.option("file")}' does not exist.".red);
      exit(1);
    }
    final content = await file.readAsString();
    final contract = SContract.fromYaml(loadYaml(content) as YamlMap);
    spinner.text = "Verifying contract...".skyBlue;
    final token = await AuthVeld.verifyContract(contract);
    spinner.success("Contract ($token) created.".skyBlue);
    exit(0);
  }
}

class AuthVeldDeleteCommand extends Command {
  @override
  final name = "delete";

  @override
  final description = "Delete a contract by its token.";

  AuthVeldDeleteCommand() {
    argParser.addOption("token", abbr: "t");
  }

  @override
  Future<void> run() async {
    final spinner =
        CliSpin(spinner: CliSpinners.bounce).start("Deleting contract...");
    await AuthVeld.deleteContract(argResults!.option("token")!);
    spinner.success("Contract deleted.");
  }
}

class AuthVeldRevokeCommand extends Command {
  @override
  final name = "revoke";

  @override
  final description = "Revoke all contracts with a given appname.";

  AuthVeldRevokeCommand() {
    argParser.addOption("appname", abbr: "a");
  }

  @override
  Future<void> run() async {
    final spinner =
        CliSpin(spinner: CliSpinners.bounce).start("Revoking contracts...");
    await AuthVeld.revokeContracts(argResults!.option("appname")!);
    spinner.success("Contracts revoked.");
  }
}

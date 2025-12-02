import 'package:args/command_runner.dart';
import 'package:reyveld/library.dart';

class AppsCommands extends Command {
  @override
  String get name => "apps";

  @override
  String get description => "Manage the external apps that Reyveld can launch.";

  AppsCommands() {
    addSubcommand(AppsAddCommand());
    addSubcommand(AppsRemoveCommand());
    addSubcommand(AppsListCommand());
  }
}

class AppsAddCommand extends Command {
  @override
  String get name => "add";

  @override
  String get description => "Add an app to Reyveld.";

  AppsAddCommand() {
    argParser.addOption("name",
        abbr: "n", help: "The name of the app.", mandatory: true);
    argParser.addOption("path",
        abbr: "p", help: "The path to the app.", mandatory: true);
  }

  @override
  Future<void> run() async {
    final name = argResults!.option("name")!;
    final path = argResults!.option("path")!;
    await AppLauncher.addApp(name, path);
  }
}

class AppsRemoveCommand extends Command {
  @override
  String get name => "remove";

  @override
  String get description => "Remove an app from Reyveld.";

  AppsRemoveCommand() {
    argParser.addOption("name",
        abbr: "n", help: "The name of the app.", mandatory: true);
  }

  @override
  Future<void> run() async {
    final name = argResults!.option("name")!;
    await AppLauncher.removeApp(name);
  }
}

class AppsListCommand extends Command {
  @override
  String get name => "list";

  @override
  String get description => "List all of the apps that Reyveld can launch.";

  @override
  Future<void> run() async {
    final apps = await AppLauncher.getApps();
    for (final app in apps) {
      print("${app.$1}: ${app.$2}");
    }
  }
}

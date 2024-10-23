import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'file_pattern.dart';
import 'extensions.dart';
import 'version_control/constellation.dart';
import 'version_control/star.dart';
import 'arceus.dart';
import 'package:interact/interact.dart';

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.

late String currentPath;

Future<dynamic> main(List<String> arguments) async {
  // AnsiX.ensureSupportsAnsi();
  var runner = CommandRunner('arceus', "The ultimate save manager.");
  runner.argParser.addOption(
    "path",
    abbr: "p",
    defaultsTo: Directory.current.path,
  );
  runner.argParser.addOption("const",
      abbr: "c",
      help:
          "Use a constellation name instead of an path. Only works after using --path to create the constellation.");
  currentPath = Directory.current.path;
  if (arguments.contains("--path") || arguments.contains("-p")) {
    currentPath =
        arguments[arguments.indexWhere((e) => e == "--path" || e == "-p") + 1];
  }
  if (arguments.contains("--const") || arguments.contains("-c")) {
    final constellationName =
        arguments[arguments.indexWhere((e) => e == "--const" || e == "-c") + 1];
    if (!Arceus.doesConstellationExist(constellationName)) {
      throw Exception(
          "Constellation with the name of $constellationName does not exist");
    }
    currentPath = Arceus.getConstellationPath(constellationName)!;
  }
  if (!Constellation.checkForConstellation(currentPath)) {
    runner.addCommand(CreateConstellationCommand());
  } else {
    runner.addCommand(ShowMapConstellationCommand());
    runner.addCommand(CheckForDifferencesCommand());
    runner.addCommand(ConstellationJumpToCommand());
    runner.addCommand(ConstellationGrowCommand());
    runner.addCommand(ConstellationDeleteCommand());
    runner.addCommand(UsersCommands());
  }
  runner.addCommand(ArceusConstellationsCommand());

  if (arguments.isNotEmpty) {
    return await runner.run(arguments);
  }
}

class CreateConstellationCommand extends Command {
  @override
  String get description =>
      "Creates a new constellation at a given, or current, path.";

  @override
  String get name => "create";

  CreateConstellationCommand() {
    argParser.addMultiOption("user", abbr: "u", defaultsTo: Iterable.empty());
  }

  @override
  void run() {
    final spinner = CliSpin().start("Creating constellation...");
    try {
      List<String>? users = argResults?["user"];
      if (users?.isEmpty ?? true) {
        Constellation(path: currentPath, name: argResults?.rest.join(" "));
      } else {
        Constellation(
            path: currentPath, name: argResults?.rest.join(" "), users: users!);
      }
    } catch (e) {
      spinner.fail("Unable to create constellation.");
      return;
    }
    spinner.success("Constellation created.");
  }
}

class ShowMapConstellationCommand extends Command {
  @override
  String get description => "Get the map of the constellation.";

  @override
  String get name => "map";

  ShowMapConstellationCommand();

  @override
  dynamic run() {
    Constellation constellation = Constellation(path: currentPath);
    constellation.starmap?.showMap();
    return jsonEncode(constellation.starmap?.toJson());
  }
}

class CheckForDifferencesCommand extends Command {
  @override
  String get description =>
      "Checks for differences between the current star and what is currently in the directory.";

  @override
  String get name => "check";

  CheckForDifferencesCommand();

  @override
  Future<bool> run() async {
    Constellation constellation = Constellation(path: currentPath);
    final spinner = CliSpin(
            text:
                "Checking for differences between current directory and provided star...")
        .start();
    bool result = constellation.checkForDifferences();
    if (!result) {
      spinner.success("No differences found.");
    } else {
      spinner.fail("Differences found.");
    }
    return result;
  }
}

class ConstellationJumpToCommand extends Command {
  @override
  String get description =>
      "Jumps to a different star in the constellation. Give a trailing hash to jump to a specific star.";

  @override
  String get name => "jump";

  ConstellationJumpToCommand();

  @override
  void run() {
    CliSpin? spinner = CliSpin().start("Jumping to star...");
    if (argResults!.rest.isEmpty) {
      spinner.fail(" Please provide a star hash to jump to.");
      return;
    }
    String hash = argResults!.rest.join("");

    try {
      final star = Constellation(path: currentPath).starmap?[hash] as Star;
      star.makeCurrent();
      spinner.success("Jumped to star \"${star.name}\".");
    } catch (e) {
      spinner.fail(" Star with the hash of \"$hash\" not found.");
      return;
    }
  }
}

class ConstellationGrowCommand extends Command {
  @override
  String get description =>
      "Continues the from the current star to a new star in the constellation. Will branch if necessary.";
  @override
  String get name => "grow";

  ConstellationGrowCommand() {
    argParser.addOption("name", abbr: "n", mandatory: true, hide: true);
  }

  @override
  void run() {
    Constellation(path: currentPath).grow(argResults?["name"]);
  }
}

class TrimCommand extends Command {
  @override
  String get description =>
      "Trims the branch at the current star. Will confirm before proceeding, unless --force is provided.";
  @override
  String get name => "trim";

  TrimCommand() {
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void run() {
    if (!argResults!["force"]) {
      final confirm = Confirm(
              prompt:
                  "Are you sure you want to trim off the current star? (Will delete the current star and its children.)",
              defaultValue: false)
          .interact();
      if (!confirm) {
        return;
      }
    }
    Constellation(path: currentPath);
  }
}

class UsersCommands extends Command {
  @override
  String get description => "Contains commands for users in the constellation.";
  @override
  String get name => "users";

  UsersCommands() {
    addSubcommand(UsersListCommand());
    addSubcommand(UsersRenameCommand());
  }
}

class UsersListCommand extends Command {
  @override
  String get description => "Lists the users in the constellation.";
  @override
  String get name => "list";

  @override
  void run() {
    Constellation(path: currentPath).userIndex?.displayUsers();
  }
}

class UsersRenameCommand extends Command {
  @override
  String get description => "Renames a user in the constellation.";
  @override
  String get name => "rename";

  UsersRenameCommand() {
    argParser.addOption("user-hash", abbr: "u", mandatory: true);
    argParser.addOption("new-name", abbr: "n", mandatory: true);
  }

  @override
  void run() {
    Constellation(path: currentPath)
        .userIndex
        ?.getUser(argResults?["user-hash"])
        .name = argResults?["new-name"];
  }
}

class ConstellationDeleteCommand extends Command {
  @override
  String get description => "Deletes the constellation. Be CAREFUL!";

  @override
  String get name => "delete";

  @override
  void run() {
    Constellation(path: currentPath).delete();
  }
}

class ReadPatternCommand extends Command {
  @override
  String get description => "Read a file using a pattern.";

  @override
  String get name => "read";

  ReadPatternCommand() {
    argParser.addOption("pattern", defaultsTo: Directory.current.path);
    argParser.addOption("file", abbr: "f", defaultsTo: Directory.current.path);
  }

  @override
  dynamic run() {
    String json = jsonEncode(
        FilePattern(argResults!.option("pattern")!.fixPath()).read(
            File(argResults!.option("file")!.fixPath()).readAsBytesSync()));
    print(json);
    return json;
  }
}

class WritePatternCommand extends Command {
  @override
  String get description => "Write a file using a pattern.";

  @override
  String get name => "write";

  WritePatternCommand() {
    argParser.addOption("data", abbr: "d", mandatory: true);
    argParser.addOption("pattern",
        abbr: "p", defaultsTo: Directory.current.path);
    argParser.addOption("file", abbr: "f", defaultsTo: Directory.current.path);
  }

  @override
  dynamic run() {
    FilePattern(argResults!.option("pattern")!.fixPath()).write(
        File(argResults!.option("file")!.fixPath()),
        jsonDecode(argResults!.option("data")!));
  }
}

class ArceusConstellationsCommand extends Command {
  @override
  String get description => "Lists all constellations.";
  @override
  String get name => "consts";

  @override
  void run() {
    if (Arceus.empty()) {
      print("No constellations found! Create one with the 'create' command.");
    }
    Arceus.getConstellationNames().forEach((e) => print("🌃 $e"));
  }
}

class ArceusInstallCommand extends Command {
  @override
  String get description => "Installs Arceus as an global applation.";
  @override
  String get name => "install";
}

class ArceusUninstallCommand extends Command {
  @override
  String get description => "Uninstalls Arceus.";
  @override
  String get name => "uninstall";
}

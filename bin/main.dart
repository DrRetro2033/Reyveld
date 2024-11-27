import 'dart:io';
import 'dart:convert';
import 'package:ansix/ansix.dart';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'version_control/constellation.dart';
import 'version_control/star.dart';
import 'arceus.dart';
import 'scripting/addon.dart';
import 'package:interact/interact.dart';
import 'cli.dart';
import 'hex_editor/editor.dart';
import 'version_control/dossier.dart';
import './server.dart';
// import 'package:cli_completion/cli_completion.dart';

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.

late String currentPath;
late bool isInternal;

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
  runner.argParser.addFlag("internal", defaultsTo: false, hide: true);
  currentPath = Directory.current.path;
  if (arguments.contains("--path") || arguments.contains("-p")) {
    currentPath =
        arguments[arguments.indexWhere((e) => e == "--path" || e == "-p") + 1];
  }
  if (arguments.contains("--const") || arguments.contains("-c")) {
    final constellationName =
        arguments[arguments.indexWhere((e) => e == "--const" || e == "-c") + 1];
    if (!Arceus.doesConstellationExist(name: constellationName)) {
      throw Exception(
          "Constellation with the name of $constellationName does not exist");
    }
    currentPath = Arceus.getConstellationPath(constellationName)!;
  }
  if (arguments.contains("--internal") || arguments.contains("-i")) {
    isInternal = true;
  } else {
    isInternal = false;
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
    runner.addCommand(StartServerCommand());
  }
  runner.addCommand(DoesConstellationExistCommand());
  runner.addCommand(ReadFileCommand());
  runner.addCommand(InstallPackagedAddonCommand());
  runner.addCommand(OpenFileCommand());
  runner.addCommand(AddonCompileCommand());
  runner.addCommand(ArceusConstellationsCommand());

  if (arguments.isNotEmpty) {
    dynamic result = await runner.run(arguments);
    if (result != null && isInternal) {
      stdout.write(result.toString());
      exit(0);
    }
  }
}

abstract class ArceusCommand extends Command {
  String getRest() {
    return argResults?.rest.join(" ") ?? "";
  }
}

class CreateConstellationCommand extends ArceusCommand {
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
        Constellation(path: currentPath, name: getRest());
      } else {
        Constellation(path: currentPath, name: getRest(), users: users!);
      }
    } catch (e) {
      spinner.fail("Unable to create constellation.");
      rethrow;
    }
    spinner.success("Constellation created.");
  }
}

class ShowMapConstellationCommand extends ArceusCommand {
  @override
  String get description => "Get the map of the constellation.";

  @override
  String get name => "map";

  ShowMapConstellationCommand();

  @override
  dynamic run() {
    Constellation constellation = Constellation(path: currentPath);
    constellation.starmap?.printMap();
    return jsonEncode(constellation.starmap?.toJson());
  }
}

class CheckForDifferencesCommand extends ArceusCommand {
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
                " Checking for differences between current directory and provided star...")
        .start();
    bool result = constellation.checkForDifferences();
    if (!result) {
      spinner.success(" No differences found.");
    } else {
      spinner.fail(" Differences found.");
    }
    return result;
  }
}

class ConstellationJumpToCommand extends ArceusCommand {
  @override
  String get description =>
      "Jumps to a different star in the constellation. Give a trailing hash to jump to a specific star.";

  @override
  String get name => "jump";

  ConstellationJumpToCommand() {
    argParser.addFlag("print",
        abbr: "p", defaultsTo: false, help: "Print the tree after jumping.");
    argParser.addFlag("force", abbr: "f", defaultsTo: false, hide: true);
  }

  @override
  void run() {
    Constellation constellation = Constellation(path: currentPath);
    if (!argResults!["force"] && constellation.checkForDifferences()) {
      final confirm = Confirm(
              prompt:
                  "There are uncommitted changes in the current directory!\nIf you jump now before growing, all progress will be lost! Are you sure you want to continue?",
              defaultValue: false)
          .interact();
      if (!confirm) {
        return;
      }
    }
    CliSpin? spinner = CliSpin().start("Jumping to star...");
    if (argResults!.rest.isEmpty) {
      spinner.fail(" Please provide a star hash to jump to.");
      return;
    }
    String hash = getRest();

    try {
      final star = constellation.starmap?[hash] as Star;
      star.makeCurrent();
      spinner.success("Jumped to star \"${star.name}\".");
      if (argResults!["print"]) {
        constellation.starmap?.printMap();
      }
    } catch (e) {
      spinner.fail(" Star with the hash of \"$hash\" not found.");
      rethrow;
    }
  }
}

class ConstellationGrowCommand extends ArceusCommand {
  @override
  String get description =>
      "Continues the from the current star to a new star in the constellation. Will branch if necessary.";
  @override
  String get name => "grow";

  ConstellationGrowCommand() {
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void run() {
    Constellation(path: currentPath)
        .grow(getRest(), force: argResults!["force"]);
  }
}

class TrimCommand extends ArceusCommand {
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
    Constellation(path: currentPath).trim();
  }
}

class UsersCommands extends ArceusCommand {
  @override
  String get description => "Contains commands for users in the constellation.";
  @override
  String get name => "users";

  UsersCommands() {
    addSubcommand(UsersListCommand());
    addSubcommand(UsersRenameCommand());
  }
}

class UsersListCommand extends ArceusCommand {
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

class ConstellationDeleteCommand extends ArceusCommand {
  @override
  String get description => "Deletes the constellation. Be CAREFUL!";

  @override
  String get name => "delete";

  ConstellationDeleteCommand() {
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void run() {
    if (!argResults!["force"]) {
      final confirm = Confirm(
              prompt:
                  "Are you sure you want to delete the constellation? (Will delete EVERYTHING in the constellation.)",
              defaultValue: false)
          .interact();
      if (!confirm) {
        return;
      }
    }
    Constellation(path: currentPath).delete();
  }
}

class AddonCompileCommand extends ArceusCommand {
  @override
  String get description => "Packages an addon for distribution.";
  @override
  String get name => "compile";

  AddonCompileCommand() {
    argParser.addOption("output",
        abbr: "o", help: "The output folder the addon should be compiled to.");
    argParser.addFlag("install-global",
        abbr: "g", help: "Install globally after compiling.");
  }

  @override
  void run() {
    if (getRest().isEmpty) {
      throw Exception("Please provide the project path for the addon.");
    }
    String projectPath = getRest();
    String outputPath = projectPath;

    if (argResults!["output"] != null) {
      outputPath = argResults!["output"]!;
    }
    CliSpin spinner = CliSpin().start(" Packaging addon... 🍱");
    final addon = Addon.package(projectPath, outputPath);
    spinner.success(" Addon packaged successfully at ${addon.path}! 🎉");

    if (argResults!["install-global"]) {
      spinner = CliSpin().start(" Installing addon globally... 🍱");
      Addon.installGlobally(addon.path);
      spinner.success(" Addon installed globally successfully! 🎉");
    }
  }
}

class InstallPackagedAddonCommand extends ArceusCommand {
  @override
  String get description => "Installs a packaged addon.";
  @override
  String get name => "install";

  InstallPackagedAddonCommand() {
    argParser.addFlag("global",
        abbr: "g", help: "Install the addon globally for all constellations.");
    // argParser.addFlag("copy",
    //     abbr: "c", help: "Copy the addon instead of moving it.");
  }

  @override
  void run() {
    if (getRest().isEmpty) {
      throw Exception(
          "Please provide the path to the addon. Addon files must end in *.arcaddon.");
    }
    String addonFile = getRest();
    CliSpin? spinner;
    if (!isInternal) {
      spinner = CliSpin().start(" Installing addon... 🍱");
    }
    if (argResults!["global"]) {
      Addon.installGlobally(addonFile);
    } else if (Constellation.checkForConstellation(currentPath)) {
      Addon.installLocally(addonFile);
    } else {
      throw Exception(
          "Please either install as a global addon or give a valid constellation first.");
    }
    if (!isInternal) {
      spinner!.success(" Addon installed successfully! 🎉");
    }
  }
}

class ReadFileCommand extends ArceusCommand {
  @override
  String get description => "Try reading a file with an associated addon.";
  @override
  String get name => "read";

  @override
  dynamic run() {
    if (getRest().isEmpty) {
      throw Exception("Please provide the file to read.");
    }
    String file = getRest();
    dynamic data = PatternAddon.getAssoiatedAddon(file).read(file);
    if (!isInternal) print(AnsiTreeView(data, theme: Cli.treeTheme));
    return jsonEncode(data);
  }
}

class ArceusConstellationsCommand extends ArceusCommand {
  @override
  String get description => "Lists all constellations.";
  @override
  String get name => "consts";

  @override
  void run() {
    if (Arceus.empty()) {
      if (!isInternal) {
        print("No constellations found! Create one with the 'create' command.");
      }
    }
    Arceus.getConstellationEntries()
        .forEach((e) => print("🌃 ${e.name} - ${e.path}"));
  }
}

class OpenFileCommand extends ArceusCommand {
  @override
  String get description => "Opens a file.";
  @override
  String get name => "open";

  @override
  Future<void> run() async {
    if (getRest().isEmpty) {
      throw Exception("Please provide the file to open.");
    }
    String file = getRest();
    if (!File(file).existsSync()) {
      throw Exception("File $file not found.");
    }
    await HexEditor(Plasma.fromFile(File(file))).interact();
    exit(0);
  }
}

class DoesConstellationExistCommand extends ArceusCommand {
  @override
  String get description =>
      "Checks if a constellation exists at the given path.";
  @override
  String get name => "exists";

  @override
  dynamic run() {
    if (getRest().isEmpty) {
      return Arceus.doesConstellationExist(path: currentPath);
    } else {
      return Arceus.doesConstellationExist(path: getRest());
    }
  }
}

class StartServerCommand extends ArceusCommand {
  @override
  String get description => "Starts the Arceus server.";

  @override
  String get name => "server";

  @override
  bool get hidden => true;

  @override
  Future<void> run() async => await ArceusServer.start();
}

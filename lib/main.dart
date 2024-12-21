import 'dart:async';
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
import 'extensions.dart';
import 'server.dart';
import 'scripting/feature_sets/feature_sets.dart';

/// # `void` main(List<String> arguments)
/// ## Main entry point.
/// Runs the CLI.
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
  Arceus.currentPath = Directory.current.path.fixPath();
  if (arguments.contains("--path") || arguments.contains("-p")) {
    Arceus.currentPath =
        arguments[arguments.indexWhere((e) => e == "--path" || e == "-p") + 1];
  }
  if (arguments.contains("--const") || arguments.contains("-c")) {
    final constellationName =
        arguments[arguments.indexWhere((e) => e == "--const" || e == "-c") + 1];
    if (!Arceus.doesConstellationExist(name: constellationName)) {
      throw Exception(
          "Constellation with the name of $constellationName does not exist");
    }
    Arceus.currentPath = Arceus.getConstellationPath(constellationName)!;
  }
  if (arguments.contains("--internal") || arguments.contains("-i")) {
    Arceus.isInternal = true;
  } else {
    Arceus.isInternal = false;
  }
  if (!Constellation.checkForConstellation(Arceus.currentPath)) {
    runner.addCommand(CreateConstellationCommand());
  } else {
    runner.addCommand(ShowMapConstellationCommand());
    runner.addCommand(CheckForDifferencesCommand());
    runner.addCommand(ConstellationJumpToCommand());
    runner.addCommand(ConstellationGrowCommand());
    runner.addCommand(ConstellationDeleteCommand());
    runner.addCommand(StartServerCommand());
    runner.addCommand(TrimCommand());
    runner.addCommand(RecoverCommand());
    runner.addCommand(ResyncCommand());
    runner.addCommand(LoginUserCommand());
  }
  runner.addCommand(UsersCommands());
  runner.addCommand(DoesConstellationExistCommand());
  runner.addCommand(ReadFileCommand());
  runner.addCommand(OpenFileInHexCommand());
  runner.addCommand(ArceusConstellationsCommand());
  runner.addCommand(AddonsCommand());

  if (arguments.isNotEmpty) {
    dynamic result = await runner.run(arguments);
    if (result != null && Arceus.isInternal) {
      stdout.write(result.toString());
    }
  }
  exit(0);
}

/// # `ArceusCommand`
/// ## An abstract class that represents a command for the Arceus CLI.
/// Use `getRest()` to get the user input.
abstract class ArceusCommand extends Command {
  String getRest() {
    return argResults?.rest.join(" ") ?? "";
  }
}

abstract class ConstellationArceusCommand extends ArceusCommand {
  Constellation get constellation => Constellation(path: Arceus.currentPath);

  @override
  dynamic run() {
    if (constellation.starmap == null) {
      print(
          "No starmap found! The constellation might be corrupted. Try running 'recover' to fix the problem.");
    } else {
      return _run();
    }
  }

  dynamic _run();
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
    if (getRest().isEmpty) {
      print("Please provide a name for the constellation!");
      return;
    }
    final spinner = CliSpin().start("Creating constellation...");
    try {
      List<String>? users = argResults?["user"];
      if (users?.isEmpty ?? true) {
        Constellation(path: Arceus.currentPath, name: getRest());
      } else {
        Constellation(path: Arceus.currentPath, name: getRest());
      }
    } catch (e) {
      spinner.fail("Unable to create constellation.");
      rethrow;
    }
    spinner.success("Constellation created.");
  }
}

class ShowMapConstellationCommand extends ConstellationArceusCommand {
  @override
  String get summary => "Shows the map of the constellation.";

  @override
  String get description => """
Shows the map of the constellation. 

The current star is marked with ✨
""";

  @override
  String get name => "map";

  ShowMapConstellationCommand();

  @override
  void _run() {
    print(
        "Currently signed in as ${constellation.loggedInUser?.name.italic()}.");
    constellation.starmap?.printMap();
    constellation.printSumOfCurStar();
  }
}

class CheckForDifferencesCommand extends ConstellationArceusCommand {
  @override
  String get description => "Checks for new changes.";

  @override
  String get name => "check";

  CheckForDifferencesCommand();

  @override
  Future<bool> _run() async {
    final spinner = CliSpin(
            text:
                " Checking for differences between current directory and provided star...")
        .start();
    bool result = constellation.checkForDifferences(false);
    if (!result) {
      spinner.success(" No differences found.");
    } else {
      spinner.fail(" Differences found.");
    }
    return result;
  }
}

class ResyncCommand extends ConstellationArceusCommand {
  @override
  String get description =>
      "Resyncs files to the current star. WILL DISCARD ANY CHANGES!";

  @override
  String get name => "resync";

  ResyncCommand();

  @override
  void _run() {
    final confirm = Confirm(
      prompt:
          " Are you sure you want to resync? This will discard any changes to tracked files.",
    ).interact();
    if (!confirm) {
      return;
    }
    constellation.resyncToCurrentStar();
    print("Resync complete ✔️");
  }
}

class RecoverCommand extends ArceusCommand {
  @override
  String get description => """
Recover from a star, without interacting with starmap.

Files will be out of sync with the starmap, so only use this when the constellation has been corrupted.
If you decide to resync back to the current star, call 'resync'.
""";

  @override
  String get summary =>
      "Recover from a star, without interacting with starmap.";

  @override
  String get name => "recover";

  RecoverCommand();

  @override
  void run() {
    Constellation constellation = Constellation(path: Arceus.currentPath);
    final files = constellation.listStarFiles();
    final stars = files.map((e) => Star(constellation, hash: e)).toList();
    final options =
        stars.map((e) => "${e.name} - ${e.createdAt.toString()}").toList();
    final selected = Select(
      prompt: " Select a star to recover.",
      options: [...options, "Cancel"],
    ).interact();
    if (selected == options.length) {
      return;
    }
    (stars[selected]).recover();
    final confirm = Confirm(
      prompt:
          " Do you also want to recreate the constellation? All other stars will be lost.",
    ).interact();
    if (confirm) {
      String name = constellation.name;
      stars.clear();
      constellation.delete();
      if (name.isEmpty) {
        name = Input(
            prompt:
                " Unable to determine constellation name. Please enter a new name.",
            validator: (p0) => p0.isNotEmpty).interact();
      }
      constellation = Constellation(path: Arceus.currentPath, name: name);
    }
    print("Recovery complete ✔️");
  }
}

class ConstellationJumpToCommand extends ConstellationArceusCommand {
  @override
  String get description => """
Jumps to a different star in the constellation.

Give it either a star hash, or use the commands below. Replace X with a number:
- root: Jumps to the root star
- recent: Jumps to the most recent star

- back: Jumps to the parent of the current star. Will be clamped to the root star.
- back X:  Will jump to the parent of every star preceeding the current star by X. Will be clamped to the the root star.
- forward`: Will jump to the first child of the current star. Will be clamped to any ending stars.
- forward X: Will jump to the Xth child of the current star. Will be clamped to a vaild index of the current star's children.

- above: Jumps to the sibling above the current star. Will wrap around to lowest star.
- above X: Will jump to the Xth sibling above the current star. Will wrap around to lowest star.
- below: Jumps to the sibling below the current star. Will wrap around to highest star.
- below X: Will jump to the Xth sibling above the current star. Will wrap around to lowest star.

- `next X`: Will jump to the Xth child of the current star. Will be wrapped to a vaild index of the current star's children.

You can also chain multiple commands together by adding a comma between each.
""";

  @override
  String get summary => "Jumps to a different star in the constellation.";

  @override
  String get name => "jump";

  ConstellationJumpToCommand() {
    argParser.addFlag("print",
        abbr: "p", defaultsTo: false, help: "Print the tree after jumping.");
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void _run() {
    if (!argResults!["force"] && constellation.checkForDifferences()) {
      final confirm = Confirm(
        prompt:
            "There are uncommitted changes in the current directory!\nIf you jump now before growing, all progress will be lost! Are you sure you want to continue?",
      ).interact();
      if (!confirm) {
        return;
      }
    }
    CliSpin? spinner = CliSpin().start(" Jumping to star...");
    if (argResults!.rest.isEmpty) {
      spinner.fail(" Please provide a star hash or command to jump.");
      return;
    }
    String hash = getRest();

    try {
      final star = constellation.starmap?[hash] as Star;
      star.makeCurrent();
      spinner.success(" Jumped to \"${star.name}\".");
      if (argResults!["print"]) {
        constellation.starmap?.printMap();
      }
    } catch (e) {
      spinner.fail(" Star with the hash of \"$hash\" not found.");
      rethrow;
    }
  }
}

class ConstellationGrowCommand extends ConstellationArceusCommand {
  @override
  String get summary =>
      "Grow from the current star to a new star with a given name.";

  @override
  String get description => """
Grow from the current star to a new star with a given name.

Growing will commit changes from tracked files into a new star in the constellation. Will branch if necessary. 
This will fail if there no changes to commit, unless '--force' is provided.""";
  @override
  String get name => "grow";

  ConstellationGrowCommand() {
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void _run() {
    if (getRest().isEmpty) {
      throw Exception("Please provide a name for the new star.");
    }
    constellation.grow(getRest(), force: argResults!["force"]);
  }
}

class TrimCommand extends ConstellationArceusCommand {
  @override
  String get summary => "Trims a star and its parents off of the starmap. ";

  @override
  String get description => """
Trims the current star and its descendants off of the starmap.

Trimming will discard all changes to tracked files, but will not destroy previous changes.
Will confirm before proceeding, unless --force is provided.
""";
  @override
  String get name => "trim";

  TrimCommand() {
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void _run() {
    if (!argResults!["force"]) {
      final confirm = Confirm(
        prompt:
            " Are you sure you want to trim off the current star? (Will discard current star and all of its descendants.)",
      ).interact();
      if (!confirm) {
        return;
      }
    }
    constellation.trim();
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
    addSubcommand(NewUserCommand());
  }
}

class UsersListCommand extends ArceusCommand {
  @override
  String get description => "Lists the users in the constellation.";
  @override
  String get name => "list";

  @override
  void run() {
    Arceus.userIndex.displayUsers();
  }
}

class UsersRenameCommand extends ArceusCommand {
  @override
  String get description => "Renames a user in the constellation.";
  @override
  String get name => "rename";

  UsersRenameCommand() {
    argParser.addOption("user-hash", abbr: "u", hide: true);
    argParser.addOption("new-name", abbr: "n", hide: true);
  }

  @override
  void run() {
    String? name = argResults?["new-name"];
    String? hash = argResults?["user-hash"];
    if (argResults?["user-hash"] == null) {
      final users = Arceus.userIndex.users;
      final names = users.map((e) => e.name).toList();
      final selected = Select(
          prompt: " Select a user to rename.",
          options: [...names, "Cancel"]).interact();
      if (selected == names.length) {
        return;
      }
      hash = users[selected].hash;
    }

    if (argResults?["new-name"] == null) {
      name = Input(
        prompt: " What would you like to name the user?",
        validator: (p0) => p0.isNotEmpty,
      ).interact();
    }

    Arceus.userIndex.getUser(hash!).name = name!;
  }
}

class NewUserCommand extends ArceusCommand {
  @override
  String get description => "Create a new user in Arceus.";

  @override
  String get name => "new";

  @override
  void run() {
    String name = getRest();
    if (name.isEmpty) {
      print("Please provide a name for the new user.");
    } else {
      Arceus.userIndex.createUser(name);
    }
  }
}

class LoginUserCommand extends ConstellationArceusCommand {
  @override
  String get description => "Login as a user in a constellation.";

  @override
  String get name => "login";

  LoginUserCommand() {
    argParser.addOption("user-hash", abbr: "u", hide: true);
    argParser.addOption("grow",
        abbr: "g", help: "Grow a new star after login.");
    argParser.addFlag("force", abbr: "f", defaultsTo: false);
  }

  @override
  void _run() {
    String? hash = argResults?["user-hash"];
    if (hash != null) {
      constellation.loginAs(Arceus.userIndex.getUser(hash));
    } else {
      final users = Arceus.userIndex.users;
      final names = users.map((e) => e.name).toList();
      final selected = Select(
          prompt: " Select a user to login as:",
          options: [...names, "Cancel"]).interact();
      if (selected == names.length) {
        // Means the user cancelled the operation.
        return;
      }
      constellation.loginAs(users[selected]);
    }
    print("Logged in as ${constellation.loggedInUser!.name}.");
    if (argResults!["grow"] != null &&
        (argResults!["grow"] as String).isNotEmpty) {
      constellation.grow(argResults!["grow"], force: argResults!["force"]);
      print("Star ${argResults!["grow"]} created.");
    }
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
                  "Are you sure you want to delete the constellation? (Will delete EVERYTHING in the constellation.)")
          .interact();
      if (!confirm) {
        return;
      }
    }
    Constellation(path: Arceus.currentPath).delete();
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
    if (!Arceus.isInternal) {
      spinner = CliSpin().start(" Installing addon... 🍱");
    }
    if (argResults!["global"]) {
      Addon.installGlobally(addonFile);
    } else if (Constellation.checkForConstellation(Arceus.currentPath)) {
      Addon.installLocally(addonFile);
    } else {
      throw Exception(
          "Please either install as a global addon or give a valid constellation first.");
    }
    if (!Arceus.isInternal) {
      spinner!.success(" Addon installed successfully! 🎉");
    }
  }
}

class UninstallAddonCommand extends ArceusCommand {
  @override
  String get description => "Uninstalls an addon.";
  @override
  String get name => "uninstall";

  @override
  void run() {
    if (getRest().isEmpty) {
      throw Exception("Please provide the name of the addon.");
    }
    String addonName = getRest();
    CliSpin? spinner;
    if (!Arceus.isInternal) {
      spinner = CliSpin().start(" Uninstalling addon... 🗑️");
    }

    final found = Addon.uninstallByName(addonName);

    if (!Arceus.isInternal && found) {
      spinner!.success(" Addon uninstalled successfully! 🎉");
    } else if (!Arceus.isInternal) {
      spinner!.fail(" Addon not found! 🚫");
    }
  }
}

class ListAddonsCommand extends ArceusCommand {
  @override
  String get description => "Lists all installed addons.";
  @override
  String get name => "list";

  @override
  void run() {
    List<Addon> addons = Addon.getInstalledAddons();
    if (addons.isEmpty) {
      print("No addons installed.");
    } else {
      for (Addon addon in addons) {
        print("🍱 ${addon.name} - ${addon.isGlobal ? "Global" : "Local"}");
      }
    }
  }
}

class AddonsCommand extends Command {
  @override
  String get description => "Commands for working with addons.";
  @override
  String get name => "addons";

  AddonsCommand() {
    addSubcommand(InstallPackagedAddonCommand());
    addSubcommand(UninstallAddonCommand());
    addSubcommand(ListAddonsCommand());
    addSubcommand(AddonCompileCommand());
  }
}

class ReadFileCommand extends ArceusCommand {
  @override
  String get summary => "Read a file with an associated addon.";
  @override
  String get description =>
      "Reads a file with an addon associated with it, so you can see a simplified view of its data.";
  @override
  String get name => "read";

  @override
  dynamic run() {
    if (getRest().isEmpty) {
      throw Exception("Please provide a file to read.");
    }
    String filepath = getRest();
    File file = File(filepath.fixPath());
    List<Addon> addons = Addon.getInstalledAddons()
        .filterByAssociatedFile(filepath.getExtension());
    if (addons.isEmpty && !Arceus.isInternal) {
      print("Unable to find an addon associated with this file!");
      return null;
    }
    Plasma plasma = Plasma.fromFile(file);
    final result = (addons.first.context as PatternAddonContext).read(plasma);
    if (!Arceus.isInternal) {
      print(AnsiTreeView(result, theme: Cli.treeTheme));
    }
    return jsonEncode(result);
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
      if (!Arceus.isInternal) {
        print("No constellations found! Create one with the 'create' command.");
      }
    }
    Arceus.getConstellationEntries()
        .forEach((e) => print("🌃 ${e.name} - ${e.path}"));
  }
}

class OpenFileInHexCommand extends ArceusCommand {
  @override
  String get description => "Opens a file in the Héx Editor.";
  @override
  String get name => "hex";

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
      return Arceus.doesConstellationExist(path: Arceus.currentPath);
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

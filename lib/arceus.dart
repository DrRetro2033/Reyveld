import 'dart:io';
import 'package:arceus/suggester.dart';
import 'package:arceus/updater.dart';
// import 'package:arceus/version_control/users.dart';
// import 'package:interact/interact.dart';

import 'package:arceus/extensions.dart';
// import 'package:arceus/version_control/constellation.dart';
import 'package:version/version.dart';
import 'package:talker/talker.dart';
import 'package:ini/ini.dart';

/// # `class` Arceus
/// ## A class that represents the Arceus application.
/// Contain global functions for Arceus, for example, settings, paths, etc.
class Arceus {
  static late String _currentPath;
  static String get currentPath => _currentPath;
  static set currentPath(String path) => _currentPath = path.fixPath();
  static late bool isInternal;
  static bool get isDev =>
      const bool.fromEnvironment('DEBUG', defaultValue: true);

  static Talker? _logger;

  static Talker get talker {
    _logger ??= Talker(
      logger: TalkerLogger(
          formatter: ArceusLogFormatter(),
          output: ArceusLogger(
                  "$appDataPath/logs/arceus-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log")
              .output),
    );
    return _logger!;
  }

  static File get mostRecentLog => File(
      "$appDataPath/logs/arceus-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log");

  /// # `static` `String` _appDataPath
  /// ## The path to the application data directory.
  static String get appDataPath => _getAppDataPath();

  /// # `static` `String` globalAddonPath
  /// ## The path to the global addons directory.
  static String get globalAddonPath => "$appDataPath/addons";

  // static UserIndex userIndex = UserIndex("$appDataPath/userindex");

  static File get _config => File("$appDataPath/config.ini");
  static Config get config {
    if (!_config.existsSync()) {
      _config.createSync(recursive: true);
    }
    return Config.fromString(_config.readAsStringSync());
  }

  static set config(Config value) {
    if (!_config.existsSync()) {
      _config.createSync(recursive: true);
    }
    _config.writeAsStringSync(value.toString());
  }

  /// # `static` `String` _getAppDataPath
  /// ## Returns the path to the application data directory.
  static String _getAppDataPath() {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.fixPath()}/arceus";
    }
  }

  /// # `static` `bool` doesConstellationExist(`String?` name, `String?` path)
  /// ## Checks if a constellation exists at the given path.
  static bool doesConstellationExist({String? name, String? path}) {
    if (name != null) {
      return getConstellationEntries().any((e) => e.name == name);
    } else if (path != null) {
      List<String> pathList = path.fixPath().split('/');
      while (pathList.length > 1) {
        if (Directory("${pathList.join('/')}/.constellation").existsSync()) {
          return true;
        }
        pathList.removeLast();
      }
      return false;
    } else {
      return false;
    }
  }

  // /// # `static` `Constellation?` getConstellationFromPath(`String` path)
  // /// ## Returns the constellation at the given path.
  // static Constellation? getConstellationFromPath(String path) {
  //   List<String> pathList = path.fixPath().split('/');
  //   while (pathList.length > 1) {
  //     if (Directory("${pathList.join('/')}/.constellation").existsSync()) {
  //       return Constellation(pathList.join('/'));
  //     }
  //     pathList.removeLast();
  //   }
  //   return null;
  // }

  /// # `static` `void` addConstellation(`String` name, `String` path)
  /// ## Adds a new constellation to the list of constellations.
  static void addConstellation(String name, String path) {
    if (doesConstellationExist(name: name)) {
      return;
    }
    final con = config;
    if (!con.hasSection("constellations")) {
      con.addSection("constellations");
    }
    con.set("constellations", name, path);
    config = con;
  }

  /// # `static` `void` removeConstellation(`String` name)
  /// ## Removes a constellation from the list of constellations.
  static void removeConstellation({String? name, String? path}) {
    if (name != null && doesConstellationExist(name: name)) {
      config.removeOption("constellations", name);
    } else if (path != null && doesConstellationExist(path: path)) {
      final constellations = getConstellationEntries();
      config.removeOption("constellations",
          constellations.firstWhere((e) => e.path == path).name);
    } else {
      throw Exception("Constellation does not exist");
    }
  }

  /// # `static` `String?` getConstellationPath(`String` name)
  /// ## Returns the path to the constellation with the given name.
  /// Throws an exception if the constellation does not exist.
  static String? getConstellationPath(String name) {
    if (!doesConstellationExist(name: name)) {
      throw Exception("Constellation does not exist");
    }
    return config.get("constellations", name);
  }

  /// # `static` `List<String>` getConstellationNames
  /// ## Returns the list of constellation names.
  static List<String> getConstellationNames() {
    return getConstellationEntries().map((e) => e.name).toList();
  }

  /// # `static` `List<ConstellationEntry>` getConstellationEntries
  /// ## Returns the list of constellation entries.
  /// Each entry contains the name and path of the constellation.
  static List<ConstellationEntry> getConstellationEntries() {
    if (!config.hasSection("constellations")) {
      return [];
    }
    return config
        .options("constellations")!
        .map((e) => ConstellationEntry(e, config.get("constellations", e)!))
        .toList();
  }

  static String getClosestConstName(String query) {
    final suggester = Suggester().addEntries(getConstellationNames());
    return suggester.suggest(query);
  }

  /// # `static` `String` getTempFolder
  /// ## Returns the path to the temp folder.
  /// Creates a new temp folder if it does not exist.
  static TemporaryDirectory getTempFolder() {
    return TemporaryDirectory(
        Directory.systemTemp.createTempSync("arceus").path);
  }

  /// # `static` `bool` empty
  /// ## Returns `true` if the list of constellations is empty, `false` otherwise.
  static bool empty() => getConstellationEntries().isEmpty;

  static String getLibraryPath() {
    return "${_getAppDataPath()}/lib";
  }

  // static User? userSelect({String prompt = "Select User"}) {
  //   final users = Arceus.userIndex.users;
  //   final names = users.map((e) => e.name).toList();
  //   final selected =
  //       Select(prompt: prompt, options: [...names, "Cancel"]).interact();
  //   if (selected == names.length) {
  //     // Means the user cancelled the operation.
  //     return null;
  //   }
  //   return users[selected];
  // }

  static void skipUpdate(String version) {
    final file = File("$appDataPath/skipupdate");
    file.createSync();
    file.writeAsStringSync(version);
  }

  static Version getSkippedVersion() {
    final file = File("$appDataPath/skipupdate");
    if (!file.existsSync()) {
      return Updater.currentVersion;
    }
    return Version.parse(file.readAsStringSync());
  }

  static Future<void> openURLInExplorer(String url) async {
    if (Platform.isWindows) {
      await Process.run("start", [url], runInShell: true);
    } else if (Platform.isLinux) {
      await Process.run("xdg-open", [url], runInShell: true);
    }
  }
}

/// # `class` ConstellationEntry
/// ## A class that represents a constellation entry.
/// Each entry contains the name and path of the constellation.
class ConstellationEntry {
  /// # final `String` name
  /// ## The name of the constellation.
  final String name;

  /// # final `String` path
  /// ## The path to the constellation.
  final String path;

  ConstellationEntry(this.name, this.path);
}

/// # `class` ArceusLogger
/// ## A class that logs messages to a file.
/// The log file is created in the application data directory.
/// Each message is appended to the file.
/// A new log file is created each day, and will log all of the messages for that day.
/// The reason for this behavior is so that if the log needs to be sent for debugging,
/// all the pertinent information is in one file and not spread across multiple logs.
class ArceusLogger {
  final File logFile;

  ArceusLogger(String path) : logFile = File(path) {
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
      logFile.writeAsStringSync("""
[Device Info]
  OS                    ${Platform.operatingSystemVersion}
  Number of Processors  ${Platform.numberOfProcessors}
  Locale                ${Platform.localeName}
  
[App Info]
  Version               ${Updater.currentVersion.toString()}

[Log]
  Date                  ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}
───────────────────────────────────────────────────────────────
""");
    }
    logFile.writeAsStringSync("""

Run at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}:${DateTime.now().second.toString().padLeft(2, "0")}.${DateTime.now().millisecond.toString().padLeft(3, "0")}
───────────────────────────────────────────────────────────────
""", mode: FileMode.append);
  }

  void output(String message) {
    logFile.writeAsStringSync("$message\n", mode: FileMode.append);
  }
}

class ArceusLogFormatter extends LoggerFormatter {
  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    return "${details.message}";
  }
}

class TemporaryDirectory {
  final String path;

  TemporaryDirectory(this.path);

  void delete() => Directory(path).deleteSync(recursive: true);
}

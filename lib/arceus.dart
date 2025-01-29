import 'dart:io';
import 'package:arceus/updater.dart';
import 'package:arceus/extensions.dart';
import 'package:version/version.dart';
import 'package:talker/talker.dart';

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

  /// # `static` `String` _getAppDataPath
  /// ## Returns the path to the application data directory.
  static String _getAppDataPath() {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.fixPath()}/arceus";
    }
  }

  /// # `static` `String` getTempFolder
  /// ## Returns the path to the temp folder.
  /// Creates a new temp folder if it does not exist.
  static TemporaryDirectory getTempFolder() {
    return TemporaryDirectory(
        Directory.systemTemp.createTempSync("arceus").path);
  }

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

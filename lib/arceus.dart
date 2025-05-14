import 'dart:io';
import 'package:arceus/extensions.dart';
import 'package:arceus/skit/skit.dart';
import 'package:version/version.dart';
import 'package:talker/talker.dart';
import 'package:arceus/version.dart' as version;

part "arceus.interface.dart";

/// Contains global functions for Arceus, for example, settings, paths, etc.
class Arceus {
  static Version get currentVersion => version.currentVersion;
  static late String _currentPath;
  static String get currentPath => _currentPath;
  static set currentPath(String path) => _currentPath = path.fixPath();
  static String get libraryPath => "$appDataPath/libraries";
  static late bool isInternal;
  static bool get isDev =>
      const bool.fromEnvironment('DEBUG', defaultValue: true);

  static Talker? _logger;

  /// The logger for Arceus.
  /// If the logger is not initialized, it will be initialized.
  static Talker get talker {
    _logger ??= Talker(
      logger: TalkerLogger(
          formatter: ArceusLogFormatter(),
          output: ArceusLogger(
                  "$appDataPath/logs/$currentVersion/arceus-$currentVersion-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log")
              .output,
          filter: ArceusLogFilter()),
    );
    return _logger!;
  }

  static File get mostRecentLog => File(
      "$appDataPath/logs/$currentVersion/arceus-$currentVersion-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log");

  /// The path to the application data directory.
  static String get appDataPath {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.fixPath()}/arceus";
    }
  }

  static Future<void> registerLibrary(String path) async {
    final file = File(path);
    try {
      await file.copy("$libraryPath/${path.getFilename()}");
    } catch (e) {
      throw Exception(
          "Failed to register library! Library has probably been registered already.");
    }
  }

  static Future<void> unregisterLibrary(String name) async =>
      await File("$libraryPath/$name.skit").delete();

  static Future<SKit> getLibrary(String name) async =>
      await SKit.open("$libraryPath/$name.skit", type: SKitType.library);

  static void printToConsole(Object message) {
    if (isDev) {
      print(message);
    }
  }
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
  Version               ${Arceus.currentVersion.toString()}

[Log]
  Date                  ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}
───────────────────────────────────────────────────────────────
""");
    }
    logFile.writeAsStringSync("""

Run at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}:${DateTime.now().second.toString().padLeft(2, "0")}.${DateTime.now().millisecond.toString().padLeft(3, "0")}
Version ${Arceus.currentVersion.toString()}
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

class ArceusLogFilter extends LoggerFilter {
  @override
  bool shouldLog(msg, LogLevel level) {
    if (level == LogLevel.debug && !Arceus.isDev) {
      return false;
    }
    return true;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:arceus/version_control/users.dart';
import 'package:interact/interact.dart';

import 'package:arceus/extensions.dart';
import 'package:arceus/version_control/constellation.dart';

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

  /// # `static` `String` _appDataPath
  /// ## The path to the application data directory.
  static String get appDataPath => _getAppDataPath();

  /// # `static` `String` globalAddonPath
  /// ## The path to the global addons directory.
  static String get globalAddonPath => "$appDataPath/addons";

  /// # `static` `File` _constellationIndex
  /// ## The file that contains the list of constellations.
  static File get _constellationIndex => File("$appDataPath/config");

  static UserIndex userIndex = UserIndex("$appDataPath/userindex");

  /// # `static` `String` _getAppDataPath
  /// ## Returns the path to the application data directory.
  static String _getAppDataPath() {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.fixPath()}/arceus";
    }
  }

  /// # `static` `Map<String, dynamic>` _getConstellations
  /// ## Returns the list of constellations.
  static Map<String, dynamic> _getConstellations() {
    if (!_constellationIndex.existsSync()) {
      return {};
    }
    return jsonDecode(_constellationIndex.readAsStringSync());
  }

  /// # `static` `bool` doesConstellationExist(`String?` name, `String?` path)
  /// ## Checks if a constellation exists at the given path.
  static bool doesConstellationExist({String? name, String? path}) {
    if (name != null) {
      return _getConstellations().containsKey(name);
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

  /// # `static` `Constellation?` getConstellationFromPath(`String` path)
  /// ## Returns the constellation at the given path.
  static Constellation? getConstellationFromPath(String path) {
    List<String> pathList = path.fixPath().split('/');
    while (pathList.length > 1) {
      if (Directory("${pathList.join('/')}/.constellation").existsSync()) {
        return Constellation(path: pathList.join('/'));
      }
      pathList.removeLast();
    }
    return null;
  }

  /// # `static` `void` addConstellation(`String` name, `String` path)
  /// ## Adds a new constellation to the list of constellations.
  static void addConstellation(String name, String path) {
    if (doesConstellationExist(name: name)) {
      return;
    }
    final index = _getConstellations();
    index[name] = path.fixPath();
    _saveConstellation(index);
  }

  /// # `static` `void` removeConstellation(`String` name)
  /// ## Removes a constellation from the list of constellations.
  static void removeConstellation({String? name, String? path}) {
    if (name != null && doesConstellationExist(name: name)) {
      final index = _getConstellations();
      index.remove(name);
      _saveConstellation(index);
    } else if (path != null && doesConstellationExist(path: path)) {
      path = path.fixPath();
      final index = _getConstellations();
      index.removeWhere((key, value) => value == path);
      // print(index);
      _saveConstellation(index);
    } else {
      throw Exception("Constellation does not exist");
    }
  }

  /// # `static` `void` _save(`Map<String, dynamic>` newIndex)
  /// ## Saves the list of constellations to the file.
  static void _saveConstellation(Map<String, dynamic> newIndex) {
    if (!_constellationIndex.existsSync()) {
      _constellationIndex.createSync(recursive: true);
    }
    _constellationIndex.writeAsStringSync(jsonEncode(newIndex));
  }

  /// # `static` `String?` getConstellationPath(`String` name)
  /// ## Returns the path to the constellation with the given name.
  /// Throws an exception if the constellation does not exist.
  static String? getConstellationPath(String name) {
    if (!doesConstellationExist(name: name)) {
      throw Exception("Constellation does not exist");
    }
    return _getConstellations()[name];
  }

  /// # `static` `List<String>` getConstellationNames
  /// ## Returns the list of constellation names.
  static List<String> getConstellationNames() {
    return _getConstellations().keys.toList();
  }

  /// # `static` `List<ConstellationEntry>` getConstellationEntries
  /// ## Returns the list of constellation entries.
  /// Each entry contains the name and path of the constellation.
  static List<ConstellationEntry> getConstellationEntries() {
    return _getConstellations()
        .entries
        .map((e) => ConstellationEntry(e.key, e.value))
        .toList();
  }

  /// # `static` `String` getTempFolder
  /// ## Returns the path to the temp folder.
  /// Creates a new temp folder if it does not exist.
  static String getTempFolder() {
    return Directory.systemTemp.createTempSync("arceus").path;
  }

  /// # `static` `bool` empty
  /// ## Returns `true` if the list of constellations is empty, `false` otherwise.
  static bool empty() => _getConstellations().isEmpty;

  static String getLibraryPath() {
    return "${_getAppDataPath()}/lib";
  }

  static User? userSelect({String prompt = "Select User"}) {
    final users = Arceus.userIndex.users;
    final names = users.map((e) => e.name).toList();
    final selected =
        Select(prompt: prompt, options: [...names, "Cancel"]).interact();
    if (selected == names.length) {
      // Means the user cancelled the operation.
      return null;
    }
    return users[selected];
  }

  static void skipUpdate(String version) {
    final file = File("$appDataPath/skipupdate");
    file.createSync();
    file.writeAsStringSync(version);
  }

  static String getSkippedVersion() {
    final file = File("$appDataPath/skipupdate");
    if (!file.existsSync()) {
      return "";
    }
    return file.readAsStringSync();
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

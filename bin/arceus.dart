import 'dart:convert';
import 'dart:io';
import 'extensions.dart';

class Arceus {
  static String get _appDataPath => _getAppDataPath();
  static String get globalAddonPath => "$_appDataPath/addons";
  static File get _constellationIndex => File("$_appDataPath/config");

  static String _getAppDataPath() {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.fixPath()}/arceus";
    }
  }

  // static String _getProgramFilesPath() {
  //   if (!Platform.environment.containsKey("PROGRAMFILES(X86)")) {
  //     return Directory.current.path;
  //   } else {
  //     return "${Platform.environment["PROGRAMFILES(X86)"]!.fixPath()}/Arceus";
  //   }
  // }

  static Map<String, dynamic> _getConstellations() {
    if (!_constellationIndex.existsSync()) {
      return {};
    }
    return jsonDecode(_constellationIndex.readAsStringSync());
  }

  static bool doesConstellationExist(String name) {
    return _getConstellations().containsKey(name);
  }

  static void addConstellation(String name, String path) {
    if (doesConstellationExist(name)) {
      throw Exception("Constellation already exists");
    }
    final index = _getConstellations();
    index[name] = path;
    _save(index);
  }

  static void removeConstellation(String name) {
    if (!doesConstellationExist(name)) {
      throw Exception("Constellation does not exist");
    }
    final index = _getConstellations();
    index.remove(name);
    _save(index);
  }

  static void _save(Map<String, dynamic> newIndex) {
    if (!_constellationIndex.existsSync()) {
      _constellationIndex.createSync(recursive: true);
    }
    _constellationIndex.writeAsStringSync(jsonEncode(newIndex));
  }

  static String? getConstellationPath(String name) {
    if (!doesConstellationExist(name)) {
      throw Exception("Constellation does not exist");
    }
    return _getConstellations()[name];
  }

  static List<String> getConstellationNames() {
    return _getConstellations().keys.toList();
  }

  static List<ConstellationEntry> getConstellationEntries() {
    return _getConstellations()
        .entries
        .map((e) => ConstellationEntry(e.key, e.value))
        .toList();
  }

  static String getTempFolder() {
    return Directory.systemTemp.createTempSync("arceus").path;
  }

  static bool empty() => _getConstellations().isEmpty;
}

class ConstellationEntry {
  final String name;
  final String path;

  ConstellationEntry(this.name, this.path);
}

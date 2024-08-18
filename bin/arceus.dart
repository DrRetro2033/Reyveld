import "dart:io";
import "uuid.dart";
import "game.dart";
import "dart:convert";
import 'package:ansix/ansix.dart';

class Arceus {
  /// The index of games managed by Arceus.
  final Map<String, dynamic> _index = {};

  /// # `Arceus()`
  /// ## Initialize the Arceus object.
  Arceus() {
    _load();
    if (!_index.containsKey("games")) {
      _index["games"] = {};
    }
  }

  /// # `void` _save()
  /// ## Internal only, should not be called directly.
  /// Saves the index to disk.
  void _save() {
    if (!(Directory("${Directory.current.path}/.arceus").existsSync())) {
      Directory("${Directory.current.path}/.arceus").createSync();
    }
    var file = File("${Directory.current.path}/.arceus/index");
    if (!file.existsSync()) {
      file.createSync();
    }
    file.writeAsStringSync(jsonEncode(_index));
  }

  /// # `void` _load()
  /// ## Internal only, should not be called directly.
  /// Loads the index from disk.
  void _load() {
    var file = File("${Directory.current.path}/.arceus/index");
    if (file.existsSync()) {
      _index.addAll(jsonDecode(file.readAsStringSync()));
    }
  }

  /// # `String` _generateUniqueHashForGame()
  /// ## Internal only, should not be called directly.
  /// Generates a unique hash for a game.
  String _generateUniqueHashForGame() {
    while (true) {
      String hash = generateUUID();
      if (!(_index.containsKey(hash))) {
        return hash;
      }
    }
  }

  /// # `void` addGame(String name, String path)
  /// ## Add a game to the index.
  void addGame(String name, String path) async {
    path = fixPath(path);
    String hash = _generateUniqueHashForGame();
    _index["games"][hash] = {"name": name, "path": path, "hash": hash};
    await Game.init(name, path, hash);
    _save();
  }

  /// # `void` removeGame(String hash)
  /// ## Remove a game from the index.
  void removeGame(String hash) {
    _index.remove(hash);
    _save();
  }

  /// # `Future<Game>` getGame(String hash) async
  /// ## Get a game from the index.
  /// Throws an exception if the game is not found.
  Future<Game> getGame(String hash) async {
    if (!_index["games"].containsKey(hash)) {
      throw Exception("Game $hash not found.");
    }
    return await Game.init(
        _index["games"][hash]["name"], _index["games"][hash]["path"], hash);
  }

  bool get isEmpty => _index.isEmpty;

  /// # `dynamic` listGames()
  /// ## Get the list of all games in the index.
  dynamic _listGames() {
    if (_index.containsKey("games")) {
      return _index["games"];
    }
    return {};
  }

  /// # `void` printGames()
  /// ## Print the list of all games in the index.
  void printGames() {
    AnsiX.printTreeView(_listGames());
  }

  void importPattern(File file) async {
    if (file.path.split(".").last != "yaml" &&
        file.path.split(".").last != "yml") {
      throw Exception("Invalid file type. Must be YAML.");
    }
    Directory("${Directory.current.path}/patterns/").createSync();
    file.copySync(
        "${Directory.current.path}/patterns/${file.path.split("/").last}");
  }

  dynamic _listPatterns() {
    Directory dir = Directory("${Directory.current.path}/patterns/");
    if (dir.existsSync()) {
      return dir.listSync();
    }
    return {};
  }

  void printPatterns() {
    AnsiX.printTreeView(_listPatterns());
  }

  String fixPath(String path) {
    path = path.replaceAll("\"", "");
    return path.replaceAll("\\", "/");
  }
}

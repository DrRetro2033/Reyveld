import "dart:io";
import "uuid.dart";
import "game.dart";
import "dart:convert";

class Arceus {
  final Map<String, dynamic> _index = {};
  Arceus() {
    _load();
    if (!_index.containsKey("games")) {
      _index["games"] = {};
    }
  }
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

  void _load() {
    var file = File("${Directory.current.path}/.arceus/index");
    if (file.existsSync()) {
      _index.addAll(jsonDecode(file.readAsStringSync()));
    }
  }

  String _generateUniqueHashForGame() {
    while (true) {
      String hash = generateUUID();
      if (!(_index.containsKey(hash))) {
        return hash;
      }
    }
  }

  void addGame(String name, String path) async {
    path = path.replaceAll("\"", "");
    path = path.replaceAll("\\", "/");
    String hash = _generateUniqueHashForGame();
    _index["games"][hash] = {"name": name, "path": path, "hash": hash};
    await Game(name, path, hash).start();
    _save();
  }

  void removeGame(String hash) {
    _index.remove(hash);
    _save();
  }

  Game getGame(String hash) {
    if (!_index.containsKey(hash)) {
      throw Exception("Game $hash not found.");
    }
    return Game(
        _index["games"][hash]["name"], _index["games"][hash]["path"], hash);
  }

  bool get isEmpty => _index.isEmpty;

  dynamic listGames() {
    if (_index.containsKey("games")) {
      return _index["games"];
    }
    return {};
  }
}

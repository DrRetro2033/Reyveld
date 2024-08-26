import "dart:io";
import "uuid.dart";
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
}

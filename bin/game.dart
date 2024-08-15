import 'dart:io';
import 'uuid.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:archive/archive_io.dart';

import 'package:hive_ce/hive.dart';

class Game {
  Box? _index;
  String name = "";
  String path = "";
  String hash = "";

  Game(this.name, this.path, this.hash) {
    if (!Directory("$path/.arceus").existsSync()) {
      Directory("$path/.arceus").createSync();
    }
    Hive.init("$path/.arceus");
  }

  /// # `Future<void>` index() async
  /// ## Load the game's index.
  /// Always call this after creating the game object, to load (or create) the index and other information.
  Future<void> index() async {
    bool alreadyExists = (await Hive.boxExists("index"));
    _index = await Hive.openBox("index");
    if (!alreadyExists) {
      _index?.put("used_hashes", []);
      createNode("Initial");
    }
  }

  /// # `String` _getUniqueHashForNode()
  /// ## Generates a new unique hash for node.
  String _getUniqueHashForNode() {
    while (true) {
      String hash = generateUUID();
      if (!_index?.get("used_hashes")?.contains(hash)) {
        _index?.get("used_hashes")?.add(hash);
        return hash;
      }
    }
  }

  /// # `void` createNode(`String name`, {`String? previous`}) async
  /// ## Create a node in time.
  /// Pass the hash of the previous node you want to connect to.
  void createNode(String name, {String? previous, bool? isFirst}) async {
    String hash = _getUniqueHashForNode();
    bool isFirst = _index!.isEmpty;
    await _index?.put(
        hash, {"name": name, "previous": previous, "next": [], "files": []});
    if (isFirst) {
      _index?.put("initialNode", hash);
    }
    if (previous != null) {
      _addNextNode(previous, hash);
    }
    _saveToNode(hash);
  }

  Future<void> _saveToNode(String hash) async {
    final encoder = ZipFileEncoder();
    encoder.create("$path/.arceus/$hash");
    for (FileSystemEntity entity in Directory(path).listSync()) {
      if (entity is File) {
        final spinner = CliSpin(
                text: "Adding ${entity.path} to Node $hash",
                spinner: CliSpinners.star)
            .start();
        await encoder.addFile(entity);
        spinner.success("Added ${entity.path} to Node $hash successfully.");
      }
    }
  }

  void _addNextNode(String hash, String next) {
    _index?.get(hash)?["next"]?.add(next);
  }

  // List<int> _findDifferencesInBytes(List<int> a, List<int> b) {
  //   List<int> differences = [];
  //   int length = a.length > b.length ? b.length : a.length;
  //   for (int i = 0; i < length; i++) {
  //     if (a.length <= i) {
  //       differences.add(i);
  //     } else if (a[i] != b[i]) {
  //       differences.add(i);
  //     }
  //   }
  //   return differences;
  // }

  // bool _isDifferent(List<int> a, List<int> b) {
  //   if (a.length != b.length) {
  //     return true;
  //   }
  //   return _findDifferencesInBytes(a, b).isNotEmpty;
  // }
}

import 'dart:io';
import 'uuid.dart';
import 'cli.dart';
import "dart:convert";
import 'package:cli_spin/cli_spin.dart';
import 'package:ansix/ansix.dart';
import 'package:archive/archive_io.dart';

class Game {
  Map<String, dynamic>? _index;
  String name = "";
  String path = "";
  String hash = "";

  /// # DO NOT CALL DIRECTLY
  /// ## Call `Game.init()` instead and await the result.
  Game(this.name, this.path, this.hash);

  /// # `Future<Game>` init(String name, String path, String hash) async
  static Future<Game> init(name, path, hash) async {
    final game = Game(name, path, hash);
    if (!Directory("$path/.arceus").existsSync()) {
      Directory("$path/.arceus").createSync();
      if (Platform.isWindows) {
        await Process.run('attrib', ['+h', "$path/.arceus"]);
      }
    }
    game._load();
    await game.index();
    return game;
  }

  Future<void> _save() async {
    File file = File("$path/.arceus/index");
    file.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(_index));
  }

  Future<void> _load() async {
    File file = File("$path/.arceus/index");
    if (file.existsSync()) {
      _index = jsonDecode(file.readAsStringSync());
    } else {
      _index = {};
    }
  }

  /// # `Future<void>` index() async
  /// ## Load the game's index.
  /// Always call this after creating the game object, to load (or create) the index and other information.
  Future<void> index() async {
    final spinner =
        CliSpin(text: "Indexing game \"$name\".", spinner: CliSpinners.star)
            .start();
    if (!_indexAlreadyExists()) {
      _index?["used_hashes"] = [];
      Cli.indentRight();
      final initalCommitHash = await createNode("Initial", isFirst: true);
      final testNode1 =
          await createNode("Test Node", previous: initalCommitHash);
      await createNode("Testing Branches", previous: testNode1);
      await createNode("Testing Branches", previous: testNode1);
      Cli.indentLeft();
    }
    _save();
    spinner.success("Finished indexing game \"$name\". HASH: $hash");
  }

  bool _indexAlreadyExists() {
    !Directory("$path/.arceus").existsSync();
    if (File("$path/.arceus/index").existsSync()) {
      return true;
    }
    return false;
  }

  /// # `String` _getUniqueHashForNode()
  /// ## Generates a new unique hash for node.
  String _getUniqueHashForNode() {
    while (true) {
      String hash = generateUUID();
      if (!_index?["used_hashes"].contains(hash)) {
        _index?["used_hashes"].add(hash);
        return hash;
      }
    }
  }

  /// # `void` createNode(`String name`, {`String? previous`}) async
  /// ## Create a node in time.
  /// Pass the hash of the previous node you want to connect to.
  Future<String> createNode(String name,
      {String? previous, bool? isFirst}) async {
    String hash = _getUniqueHashForNode();
    final spinner = CliSpin(
            indent: 1,
            text: "Creating \"$name\" with hash $hash",
            spinner: CliSpinners.star)
        .start();
    _index?[hash] = {"name": name, "hash": hash, "next": []};
    if (isFirst ?? false) {
      _index?["initialNode"] = hash;
    }
    if (previous != null) {
      _addNextNode(previous, hash);
    }
    Cli.indentRight();
    await _saveNode(hash);
    Cli.indentLeft();
    spinner.success("Successfully added $hash to tree.");
    _save();
    return hash;
  }

  Future<void> _saveNode(String hash) async {
    final encoder = ZipFileEncoder();
    encoder.create("$path/.arceus/$hash");
    for (FileSystemEntity entity in Directory(path).listSync()) {
      if (entity is File) {
        final spinner = CliSpin(
                indent: Cli.indent,
                text: "Adding ${entity.path} to Node $hash",
                spinner: CliSpinners.star)
            .start();
        try {
          await encoder.addFile(entity);
        } catch (e) {
          spinner.warn(
              "File ${entity.path} could not be added to node (Most likely due to an online storage provider.) Skipping.");
          continue;
        }
        spinner.success("Added ${entity.path} to Node $hash successfully.");
      }
    }
  }

  void _addNextNode(String hash, String next) {
    final node = _index?[hash];
    if (node != null) {
      (node["next"] as List<dynamic>).add(next);
      _index?[hash] = node;
    }
  }

  Future<void> printIndex() async {
    AnsiX.printTreeView((await _getNodeTree()).toJson(),
        theme: AnsiTreeViewTheme(
          showListItemIndex: false,
          headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
          valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
          anchorTheme: AnsiTreeAnchorTheme(
              style: AnsiBorderStyle.rounded, color: AnsiColor.blueViolet),
        ));
  }

  /// # `Future<Node>` _getNodeTree() async
  /// ## Get the node tree from the index.
  /// Returns the root node of the tree in the form of a `Node` object.
  Future<Node> _getNodeTree() async {
    String hash = _index?["initialNode"];
    final firstNodeInTree = Node(hash, _index?[hash]["name"]);
    Map<String, Node> nodes = {hash: firstNodeInTree};
    List<Node> buffer = [firstNodeInTree];
    while (buffer.isNotEmpty) {
      final node = buffer.first;
      nodes[node.hash] = node;
      for (String next in _index?[node.hash]["next"] ?? []) {
        nodes[next] = Node(next, _index?[next]["name"]);
        buffer.add(nodes[next]!);
        node.addNextNode(nodes[next]!);
      }
      buffer.remove(node);
    }
    return firstNodeInTree;
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

/// # `class` `Node`
/// ## A node in the game tree.
/// Contains a list of the next nodes and the name and hash of the node.
/// TODO: Move code from inside of `Game` that modifies the tree, and move it here.
class Node {
  List<Node>? next;
  String? name;
  String hash;

  Node(this.hash, this.name);

  void addNextNode(Node node) {
    next ??= [];
    next!.add(node);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> list = {};
    String displayName = "$name - $hash";
    list[displayName] = {};
    for (int x = 1; x < ((next?.length) ?? 0); x++) {
      list[displayName].addAll(next?[x].toJson());
    }
    list.addAll(next?.first.toJson() ?? {});
    return list;
  }
}

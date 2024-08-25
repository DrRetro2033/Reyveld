import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'package:archive/archive_io.dart';
// import 'cli.dart';
// import 'package:cli_spin/cli_spin.dart';
import 'package:ansix/ansix.dart';
import 'package:archive/archive_io.dart';

import 'extensions.dart';
import 'uuid.dart';

/// # `class` Universe
/// ## A collection of planets that represents a universe.
/// A universe can be used for a series of games, like for example Mass Effect. Universes will not only help with organizing your saves, but also help with transfering data between planets/games.
class Universe {
  List<Planet> planets = [];
}

/// # `class` Planet
/// ## A collection of tree that represents a planet.
/// Planets are used for a individual game, and keeps data about that game. A planet can be by itself, or can be in an universe.
class Planet {
  String? name;
  String path;
  List<Tree> trees = [];

  String get planetPath {
    return "$path/.planet";
  }

  Planet(this.path) {
    _insurePlanetDirectory();
  }

  void _insurePlanetDirectory() {
    if (!(Directory(planetPath).existsSync())) {
      Directory(planetPath).createSync();
      if (Platform.isWindows) {
        Process.runSync('attrib', ['+h', planetPath]);
      }
    }
  }
}

/// # `class` Tree
/// ## A tree that represents a file's or directory's history in a forest.
class Tree {
  Planet planet;
  String? name;
  String associatedPath;

  String get associatedEntry {
    return associatedPath.split("/").last;
  }

  String get treePath {
    return "${planet.planetPath}/$associatedEntry.tree";
  }

  /// The root leaf of the tree. Not the same as current leaf.
  Leaf? root;

  /// The leaf the tree is currently on. All commands that modify the tree will always modify the current leaf.
  /// So if you want to view or change a leaf that is not the current leaf, you need to change the current leaf
  /// to the leaf you want to view or change.
  Leaf? currentLeaf;

  Tree(this.associatedPath, this.planet, {this.name}) {
    if (File(treePath).existsSync()) {
      load();
    } else {
      _createRootLeaf();
      save();
    }
  }

  void load() {
    var file = File(treePath);
    if (file.existsSync()) {
      _fromJson(jsonDecode(file.readAsStringSync().decompress()));
    }
  }

  void save() {
    var file = File(treePath);
    if (!file.existsSync()) {
      file.createSync();
    }
    String json = jsonEncode(_toJson()).compress();
    file.writeAsStringSync(json);
  }

  void jumpTo(String leafHash) {
    _setCurrentLeaf(Leaf(this, hash: leafHash));
  }

  void jumpToRoot() {
    _setCurrentLeaf(root!);
  }

  void jumpToChild(int childIndex) {
    try {
      _setCurrentLeaf(currentLeaf!.childern[childIndex]);
    } catch (e) {
      throw Exception("Invalid child index.");
    }
  }

  void jumpToParent() {
    _setCurrentLeaf(currentLeaf!.parent ?? root!);
  }

  void jumpToSibling(int siblingIndex) {
    _setCurrentLeaf(currentLeaf!.parent!.childern[siblingIndex]);
  }

  void jumpToMostRecent() {
    _setCurrentLeaf(root!.getMostRecentLeaf());
  }

  /// # `void` rollback()
  /// ## Rollback the tree to the current leaf.
  void rollback() {
    currentLeaf?.unarchive();
  }

  /// # 'void` split(`String` `nameOfNewLeaf`)
  /// ## Create a new leaf off of the current leaf.
  void split(String nameOfNewLeaf) {
    Leaf newLeaf = currentLeaf!.newLeaf(nameOfNewLeaf);
    _setCurrentLeaf(newLeaf);
  }

  void _setCurrentLeaf(Leaf leaf) {
    currentLeaf = leaf;
    save();
  }

  void _fromJson(Map<String, dynamic> json) {
    name = json["name"];
    root = Leaf(this, hash: json["root"]);
    currentLeaf = Leaf(this, hash: json["current"]);
  }

  Map<String, dynamic> _toJson() {
    return {"name": name, "root": root!.hash, "current": currentLeaf!.hash};
  }

  void _createRootLeaf() {
    root = Leaf(this, name: "Initial Leaf");
    currentLeaf = root!;
  }

  void printTree() {
    AnsiX.printTreeView((root?.getReadableTree()),
        theme: AnsiTreeViewTheme(
          showListItemIndex: false,
          headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
          valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
          anchorTheme: AnsiTreeAnchorTheme(
              style: AnsiBorderStyle.rounded, color: AnsiColor.blueViolet),
        ));
  }
}

/// # `Leaf`
/// ## A leaf in a tree that represents a point in time in a Tree.
class Leaf {
  Tree tree;
  Seed? seed;
  String? hash;
  String? name;
  late DateTime timeCreated;
  Leaf? parent;
  List<Leaf> childern = [];

  Uint8List? bytes;

  Leaf(this.tree, {this.hash, this.name, this.parent}) {
    if (hash != null && name == null) {
      load();
    } else if (hash == null && name != null) {
      timeCreated = DateTime.now();
      _create();
    }
    throw Exception(
        "Leaf must have either a hash to load from, or a name to create.");
  }

  void _create() {
    while (true) {
      hash = generateUUID();
      if (!(File("${tree.associatedPath}/$hash.leaf").existsSync())) {
        break;
      }
    }
    seed = Seed(tree, path: tree.associatedPath);
    seed?.archive();
    save();
  }

  void load() {
    var file = File("${tree.associatedPath}/$hash.leaf");
    if (file.existsSync()) {
      String json = file.readAsStringSync().decompress();
      Map<String, dynamic> data = jsonDecode(json);
      _fromJson(data);
    }
  }

  Leaf newLeaf(String name) {
    Leaf newLeaf = Leaf(tree, name: name, parent: this);
    childern.add(newLeaf);
    save();
    return newLeaf;
  }

  /// # `Future<void>` save() async
  /// ## Save the leaf to disk.
  /// First, Arceus will archive the associated file and then save the leaf to disk.
  void save() async {
    String json = jsonEncode(toJson()).compress();
    if (!(Directory("${Directory.current.path}/.arceus").existsSync())) {
      Directory("${Directory.current.path}/.arceus").createSync();
    }
    var file = File("${Directory.current.path}/.arceus/$hash.leaf");
    if (!file.existsSync()) {
      file.createSync();
    }
    file.writeAsStringSync(json);
    for (Leaf child in childern) {
      child.save();
    }
  }

  void _fromJson(Map<String, dynamic> json) {
    name = json["name"];
    seed = Seed(tree, hash: json["seed"]);
    timeCreated = DateTime.parse(json["time"]);
    List<dynamic> children = json["children"];
    for (dynamic child in children) {
      childern.add(Leaf(tree, hash: child));
    }
    bytes = utf8.encode(json["bytes"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "seed": seed?.hash,
      "time": timeCreated.toString(),
      "children": childern.map((e) => e.hash).toList(),
      "bytes": utf8.decode(bytes!.toList())
    };
  }

  Map<String, dynamic> getReadableTree() {
    Map<String, dynamic> list = {};
    String displayName = "$name - $hash";
    list[displayName] = {};
    for (int x = 1; x < ((childern.length)); x++) {
      list[displayName].addAll(childern[x].toJson());
    }
    list.addAll(childern[0].getReadableTree());
    return list;
  }

  void unarchive() {
    seed?.unarchive();
  }

  Leaf getMostRecentLeaf() {
    Leaf recent = this;
    if (childern.isEmpty) {
      return recent;
    }
    for (Leaf child in childern) {
      if (child.timeCreated.isAfter(recent.timeCreated)) {
        recent = child;
      }
    }
    return recent.getMostRecentLeaf();
  }
}

class Seed {
  String? hash;
  String? path;
  Tree tree;

  Seed(this.tree, {this.path, this.hash}) {
    if (hash == null && path != null) {
      _figureOutHash();
      archive();
    }
  }

  String get seedPath => "${tree.planet.planetPath}/seeds/$hash.seed";

  void _figureOutHash() {
    while (true) {
      hash = generateUUID();
      if (!(File(seedPath).existsSync())) {
        break;
      }
    }
  }

  void archive() {
    var archive = ZipFileEncoder();
    archive.create(seedPath);
    if (File(path!).existsSync()) {
      var file = File(path!);
      archive.addFile(file);
    } else if (Directory(path!).existsSync()) {
      var dir = Directory(path!);
      for (var entity in dir.listSync()) {
        if (entity is File) {
          archive.addFile(entity);
        } else if (entity is Directory) {
          archive.addDirectory(entity);
        }
      }
    }
  }

  void unarchive() {
    extractFileToDisk(seedPath, "out");
  }
}

import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/star.dart';
import 'package:arceus/widget_system.dart';

class Constellation extends SObject {
  Constellation(super._kit, super._node);

  String get name => get("name") ?? "Constellation";

  String get path => get("path")!.fixPath();

  String get currentHash => get("cur") ?? "";

  set currentHash(String value) => set("cur", value);

  Uri get uri => Uri.parse(path);

  set path(String value) => set("path", value.fixPath());

  Star get root => getChild<Star>()!;

  /// Creates the root [Star] of the constellation.
  /// This is used when creating a new constellation.
  Future<Star> createRootStar() async {
    final archive = await kit.archiveFolder(path);
    final rootStar = await StarFactory().create(kit, {
      "name": "Initial Star",
      "archiveHash": archive.hash,
      "hash": newStarHash()
    });
    addChild(rootStar);
    currentHash = rootStar.hash;
    return rootStar;
  }

  /// Returns the current star in the constellation.
  /// If the current star is not found, it returns the root star.
  Star getCurrentStar() {
    final stars = getDescendants<Star>();
    for (final star in stars) {
      if (star!.hash == currentHash) {
        return star;
      }
    }
    currentHash = root.hash;
    return root;
  }

  /// Returns all of the hashes of the stars in the constellation.
  Set<String> getStarHashes() {
    final stars = getDescendants<Star>();
    final hashes = <String>{};
    for (final star in stars) {
      hashes.add(star!.hash);
    }
    return hashes;
  }

  /// Generates a new unique hash that is not used by any of the stars in the constellation.
  /// This is used when creating a new star.
  ///
  /// Returns a new unique hash.
  String newStarHash() {
    final hashes = getStarHashes();
    return generateUniqueHash(hashes);
  }

  /// Prints the tree of the stars in the constellation, with each level of indentation showing the parents of the stars.
  void printTree() {
    print(TreeWidget(_getTreeForPrint(root, {})));
  }

  /// Returns the tree of the star and its children, for printing.
  /// This is called recursively, to give a reasonable formatting to the tree, by making single children branches be in one column, instead of infinitely nested.
  Map<String, dynamic> _getTreeForPrint(Star star, Map<String, dynamic> tree,
      {bool branch = false}) {
    final starName = star.getDisplayName();
    tree[starName] = <String, dynamic>{};
    if (star.getChildren<Star>().length == 1) {
      if (branch) {
        tree[starName].addAll(_getTreeForPrint(star.getChild<Star>()!, {}));
        return tree;
      }
      return _getTreeForPrint(star.getChild<Star>()!, tree);
    } else {
      for (final child in star.getChildren<Star>()) {
        tree[starName].addAll(_getTreeForPrint(child!, {}, branch: true));
      }
    }
    return tree;
  }
}

class ConstFactory extends SFactory<Constellation> {
  @override
  get requiredAttributes => {
        "name": (e) => e is String && e.isNotEmpty,
        "path": (e) async =>
            e is String && e.isNotEmpty && await Directory(e).exists()
      };

  @override
  Constellation load(SKit kit, XmlNode node) => Constellation(kit, node);

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("const", nest: () {
          builder.attribute("name", attributes["name"]);
          builder.attribute("path", attributes["path"]);
        });
      };

  @override
  String get tag => "const";
}

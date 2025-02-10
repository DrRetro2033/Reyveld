import 'dart:async';
import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/star.dart';
import 'package:arceus/widget_system.dart';

part 'constellation.g.dart';

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

  Star getMostRecentStar() {
    final stars = getDescendants<Star>();
    stars.sort((a, b) => b!.createdOn.compareTo(a!.createdOn));
    return stars.last ?? root;
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

  Star getStarAt(String commandString) {
    List<String> commands = commandString.split(",");
    Star current = getCurrentStar();
    for (String command in commands) {
      command = command.trim(); // Remove any whitespace.
      if (command == "recent") {
        // Jump to most recent star.
        current = getMostRecentStar();
      } else if (command == "root") {
        // Jump to root star.
        current = root;
      } else if (command.startsWith("forward")) {
        // Jump forward by X stars.
        final x = command.replaceFirst("forward", "");
        int i = int.tryParse(x) ?? 1;
        Star star = current;
        while (i > 0) {
          star = star.getChild<Star>() ?? current;
          i--;
        }
        current = star;
      } else if (command.startsWith("back")) {
        // Jump back by X stars.
        final x = command.replaceFirst("back", "");
        int? i = int.tryParse(x.trim()) ?? 1;
        Star star = current;
        while (i! > 0) {
          star = star.getParent<Star>() ?? root;
          i--;
        }
        current = star;
      } else if (command.startsWith("above")) {
        // Jump above
        final x = command.replaceFirst("above", "");
        int i = int.tryParse(x) ?? 1;
        while (i > 0) {
          current = current.getSiblingAbove<Star>() ?? current;
          i--;
        }
      } else if (command.startsWith("below")) {
        // Jump below
        final x = command.replaceFirst("below", "");
        int i = int.tryParse(x) ?? 1;
        while (i > 0) {
          current = current.getSiblingBelow<Star>() ?? current;
          i--;
        }
      } else if (command.startsWith("next")) {
        // Jump to next child
        final x = command.replaceFirst("next", "");
        int? i = int.tryParse(x) ?? 1;
        final children = current.getChildren<Star>();
        current = children[i % children.length] ?? current;
      } else if (command.startsWith("depth")) {
        // Jump to depth
        final x = command.replaceFirst("depth", "");
        int? i = int.tryParse(x) ?? 1;
        current =
            current.getDescendants<Star>(filter: (e) => e.getDepth() == i)[0] ??
                current.getDescendants<Star>().last ??
                current;
      }
    }
    return current;
  }
}

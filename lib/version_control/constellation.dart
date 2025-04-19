import 'dart:async';

import 'package:arceus/extensions.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/file_system.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/star.dart';

part 'constellation.g.dart';

@SGen("const")
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
    final archive = await SArchiveCreator.archiveFolder(kit, path);
    final rootStar =
        await StarCreator("Initial Star", newStarHash(), archive.hash)
            .create(kit);
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
    stars.sort((a, b) => a!.createdOn.compareTo(b!.createdOn));
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
          Star? x = current;
          Star? sibling;
          while (sibling == null) {
            if (x == null) {
              break;
            }
            sibling = x.getSiblingAbove<Star>();
            x = x.getParent<Star>();
          }
          current = sibling ?? current;
          i--;
        }
      } else if (command.startsWith("below")) {
        // Jump below
        final x = command.replaceFirst("below", "");
        int i = int.tryParse(x) ?? 1;
        while (i > 0) {
          Star? x = current;
          Star? sibling;
          while (sibling == null) {
            if (x == null) {
              break;
            }
            sibling = x.getSiblingBelow<Star>();
            x = x.getSiblingBelow<Star>();
          }
          current = sibling ?? current;
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

  Future<bool> checkForChanges() {
    return getCurrentStar().checkForChanges();
  }

  Future<void> updateToCurrent() async {
    return await getCurrentStar().archive.then((e) async => e!.extract(path));
  }
}

extension ConstellationExtension on SKit {
  Future<Constellation?> getConstellation() async {
    final header = await getHeader();
    return header?.getChild<Constellation>();
  }
}

class ConstellationInterface extends SObjectInterface<Constellation> {
  @override
  get className => "Constellation";

  @override
  get description => """
A collection of Stars, with a root star, and a current star.
""";

  @override
  get exports => {
        "name": (_) => object?.name,
        "path": (_) => object?.path,
        "getCurrent": (_) => object?.getCurrentStar(),
        "getRoot": (_) => object?.root,
        "getAt": (state) async {
          final commandString = await state.getFromTop<String>();
          return object?.getStarAt(commandString);
        }
      };

  @override
  get statics => {
        "new": (state) async {
          final path = await state.getFromTop<String>();
          final name = await state.getFromTop<String>();
          final kit = await state.getFromTop<SKit>();
          final constellation =
              await ConstellationCreator(name, path).create(kit);
          await constellation.createRootStar();
          return constellation;
        }
      };
}

class ConstellationCreator extends SCreator<Constellation> {
  final String name;
  final String path;

  ConstellationCreator(this.name, this.path);

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("path", path);
      };
}

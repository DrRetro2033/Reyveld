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
    kit.addRoot(archive);
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

  Future<bool> checkForChanges() {
    return getCurrentStar().checkForChanges();
  }

  Future<void> updateToCurrent() async {
    return await getCurrentStar().archive.then((e) async => e!.extract(path));
  }

  Future<SArchive> getUnsavedChanges() async {
    final archive = await SArchiveCreator.archiveFolder(kit, path);
    if (!await archive
        .isDifferent(await getCurrentStar().archive.then((e) async => e!))) {
      return await getCurrentStar().archive.then((e) async => e!);
    }
    return archive;
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
        "name": (
          "Gets the name of the constellation.",
          {},
          String,
          (_) => object?.name
        ),
        "path": (
          "Gets the path of the constellation.",
          {},
          String,
          (_) => object?.path
        ),
        "current": (
          "Gets the current star of the constellation.",
          {},
          Star,
          (_) => object?.getCurrentStar()
        ),
        "root": (
          "Gets the root star of the constellation.",
          {},
          Star,
          (_) => object?.root
        ),
        "recent": (
          "Gets the most recent star of the constellation.",
          {},
          Star,
          (_) => object?.getMostRecentStar()
        ),
        "unsaved": (
          "Gets an archive that contains all of the unsaved changes in the constellation.",
          {},
          SArchive,
          (_) => object?.getUnsavedChanges()
        )
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

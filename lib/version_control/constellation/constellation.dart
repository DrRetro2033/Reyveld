import 'dart:async';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/file_system/file_system.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/star/star.dart';

part 'constellation.g.dart';
part 'constellation.interface.dart';
part 'constellation.creator.dart';

@SGen("const")
class Constellation extends SObject {
  Constellation(super._node);
  String get name => get("name") ?? "Constellation";

  set name(String value) => set("name", value.formatForXML());

  String get path => get("path")!.fixPath();

  String get currentHash => get("cur") ?? "";

  set currentHash(String value) => set("cur", value);

  set path(String value) => set("path", value.fixPath());

  /// Returns the root [Star] of the constellation.
  Star get root {
    final root = getChild<Star>();
    if (root == null) {
      throw Exception(
          "Constellation has no root star! Please start the constellation by calling start() in Lua before using it!");
    }
    return root;
  }

  /// Creates the root [Star] of the constellation.
  /// This is used when creating a new constellation.
  Future<Star> createRootStar() async {
    final archive = await SArchiveCreator.archiveFolder(path);
    await kit.addRoot(archive);
    final rootStar = await StarCreator(
            "Initial Star", newStarHash(), await archive.newIndent())
        .create();
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

  /// Checks for changes from the current star, and returns true if
  /// there are changes, false if there are none.
  Future<bool> checkForChanges() {
    return getCurrentStar().checkForChanges();
  }

  /// Updates the tracked folder to the current star.
  Future<void> updateToCurrent() async {
    return await getCurrentStar().archive.then((e) async => e!.extract(path));
  }

  /// Returns an archive with unsaved changes in the tracked folder.
  Future<SArchive> getUnsavedChanges() async {
    final archive = await SArchiveCreator.archiveFolder(path);
    if (!await archive
        .isDifferent(await getCurrentStar().archive.then((e) async => e!))) {
      return await getCurrentStar().archive.then((e) async => e!);
    }
    return archive;
  }
}

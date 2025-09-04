import 'dart:async';

import 'package:reyveld/extensions.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:reyveld/skit/sobjects/file_system/file_system.dart';
import 'package:reyveld/skit/sobjects/file_system/filelist/filelist.dart';
import 'package:reyveld/uuid.dart';
import 'package:reyveld/version_control/star/star.dart';

part 'constellation.g.dart';
part 'constellation.interface.dart';
part 'constellation.creator.dart';

/// This class represents a constellation in a kit file.
/// A constellation is a collection of [Star]s, which describes the history of a folder.
@SGen("const")
class Constellation extends SObject {
  Constellation(super._node);

  /// The name of the constellation.
  String get name => get("name") ?? "Constellation";
  set name(String value) => set("name", value);

  /// The current hash of the constellation.
  String get currentHash => get("cur") ?? "";
  set currentHash(String value) => set("cur", value);

  /// The tracked path of the constellation.
  String get path => get("path")!;
  set path(String value) => set("path", value);

  /// Returns the root [Star] of the constellation.
  Star get root {
    final root = getChild<Star>();
    if (root == null) {
      throw Exception(
          "Constellation has no root star! Please start the constellation by calling start() in Lua before using it!");
    }
    return root;
  }

  /// Returns true if the constellation has a root star.
  bool get hasRoot => getChild<Star>() != null;

  /// Returns the globs of the constellation.
  Globs? get globs => getChild<Globs>();
  set globs(Globs? value) {
    if (getChild<Globs>() != null) {
      getChild<Globs>()!.unparent();
    } else {
      addChild(value!);
    }
  }

  /// Creates the root [Star] of the constellation.
  /// This is used when creating a new constellation.
  Future<Star> createRootStar({bool throwIfExists = true}) async {
    if (hasRoot) {
      if (throwIfExists) {
        throw Exception(
            "Constellation already has a root star! Do not call this function twice!");
      }
      return root;
    }
    final archive = await SArchiveCreator.archiveFolder(path.resolvePath(),
        includeList: globs);
    await kit.addRoot(archive);
    final rootStar = await StarCreator(
            "Initial Star", newStarHash(), await archive.newIndent(),
            branch: "main")
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

  /// Get the start of a branch.
  /// Also known as the anchor/stem star.
  Star? getStartOfBranch(String branch) {
    return getDescendants<Star>(
            filter: (star) => star.has("branch") && star.branchName == branch)
        .firstOrNull;
  }

  /// Returns all of the branches in the constellation.
  Set<String> getAllBranches() =>
      getDescendants<Star>(filter: (star) => star.has("branch"))
          .map((e) => e!.branchName)
          .toSet();

  /// Checks for changes from the current star, and returns true if
  /// there are changes, false if there are none.
  Future<bool> checkForChanges() async {
    return await getCurrentStar().checkForChanges();
  }

  /// Syncs the tracked folder to the current star.
  Future<Stream<String>> sync() async {
    return await getCurrentStar().checkout(path);
  }

  /// Returns an archive with unsaved changes in the tracked folder.
  Future<SArchive> getUnsavedChanges() async {
    final archive = await SArchiveCreator.archiveFolder(path.resolvePath());
    if (!await archive.checkForChanges(path.resolvePath())) {
      return await getCurrentStar().archive.then((e) async => e!);
    }
    return archive;
  }

  Star? getStarByHash(String hash) =>
      getDescendants<Star>(filter: (star) => star.hash == hash).firstOrNull;
}

import 'package:arceus/extensions.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/file_system/file_system.dart';
import 'package:arceus/version_control/constellation/constellation.dart';

part 'star.g.dart';
part 'star.interface.dart';
part 'star.creator.dart';

/// This class represents a star in a constellation.
/// A star is a node in the constellation tree, and contains a reference to an archive.
@SGen("star")
class Star extends SObject {
  Star(super._node);

  /// The name of the star.
  String get name => get("name", decode: true) ?? "Initial Star";
  set name(String value) => set("name", value, encode: true);

  /// The hash of the star.
  String get hash => get("hash")!;
  set hash(String value) => set("hash", value);

  /// Returns the archive of the star.
  Future<SArchive?> get archive async => await getChild<SRArchive>()?.getRef();

  /// Returns the date the star was created.
  DateTime get createdOn => DateTime.parse(get("date")!);

  /// Returns the constellation of the star.
  Constellation get constellation => getAncestors<Constellation>().first!;

  /// Returns true if the star is the root star.
  bool get isRoot => getParent<Constellation>() != null;

  /// Returns true if the star is the current star.
  bool get isCurrent => constellation.currentHash == hash;

  /// Returns true if the star is a single child.
  bool get isSingleChild => getParent<Star>()?.getChildren<Star>().length == 1;

  /// Returns true if the star is a leaf.
  bool get isLeaf => getChildren<Star>().isEmpty;

  /// Returns true if the star is the stem of a branch.
  bool get isStem => has("branch");

  /// Returns the branch name of the star.
  String get branchName => stem.get("branch", decode: true)!;

  /// Returns the anchor star of the branch.
  Star get stem {
    final stem = has("branch")
        ? this
        : getAncestors<Star>(filter: (star) => star.has("branch")).first!;
    return stem;
  }

  /// Anchors the star, making it the stem of a new branch.
  void makeStem(String name) {
    /// If the branch name already exists, throw an exception.
    if (constellation.getAllBranches().contains(name)) {
      throw Exception("Branch name already exists.");
    }
    set("branch", name, encode: true);
  }

  /// Unanchors the star.
  void unmakeStem() {
    /// If the star is the root star, it cannot be unanchored, so it will do nothing and return.
    if (isRoot) return;
    set("branch", null);
  }

  /// Grows a new star from this star.
  /// Returns the new star.
  Future<Star> grow(String name, {String? branchName}) async {
    /// The new star.
    Star star;

    /// If there are no changes, create a new star with the exact same archive reference.
    /// If there are changes, create a new star with a new archive that references the old archive.
    if (!await checkForChanges()) {
      star = await StarCreator(name, constellation.newStarHash(),
              getChild<SRArchive>()!.copy() as SRArchive)
          .create();
    } else {
      final newArchive = await SArchiveCreator.archiveFolder(
          constellation.path.resolvePath(),
          ref: await archive,
          includeList: constellation.globs);
      await kit.addRoot(newArchive);
      star = await StarCreator(
              name, constellation.newStarHash(), await newArchive.newIndent())
          .create();
    }
    addChild(star);

    if (branchName != null) {
      star.makeStem(branchName);
    }

    return star;
  }

  /// Trims a star from the constellation.
  /// Will throw an exception if the star is the root star.
  /// The parent star will become current, the archive will be marked for deletion, and the star will be unparented.
  Future<void> trim() async {
    if (isRoot) {
      throw Exception("Cannot trim root star!");
    }
    getParent<Star>()!.makeCurrent();
    await constellation.sync();
    await archive.then((e) => e!.markForDeletion());
    for (final archiveReference in getDescendants<SRArchive>()) {
      archiveReference!.markForDeletion();
    }
    unparent();
  }

  /// Makes this star the current star.
  void makeCurrent() async {
    constellation.currentHash = hash;
  }

  /// Checks for changes from the current star, and returns true if there are changes, false if there are none.
  Future<bool> checkForChanges() async {
    return await archive.then<bool>((value) => value!.checkForChanges(
        constellation.path.resolvePath(),
        includeList: constellation.globs));
  }
}

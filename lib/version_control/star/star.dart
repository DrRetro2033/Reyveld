import 'package:reyveld/extensions.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:reyveld/skit/sobjects/file_system/file_system.dart';
import 'package:reyveld/uuid.dart';
import 'package:reyveld/version_control/constellation/constellation.dart';

part 'star.g.dart';
part 'star.interface.dart';
part 'star.creator.dart';

/// This class represents a star in a constellation.
/// A star is a node in the constellation tree, and contains a reference to an archive.
@SGen("star")
@LuaClass(
  """This class represents a star in a constellation.
A star is a point in time that represents a snapshot of an folder.""",
)
class Star extends SObject {
  Star(super._node);

  @override
  childAllowed(object) {
    if (object is Star || object is SRArchive) {
      return (true, "");
    }
    return (false, "Cannot add a ${object.runtimeType} to an $runtimeType!");
  }

  /// The name of the star.
  @LuaExport("The name of the star.")
  String get name => get("name") ?? "Initial Star";
  set name(String value) => set("name", value);

  /// The hash of the star.
  String get hash => get("hash")!;
  set hash(String value) => set("hash", value);

  SRArchive? get archiveRef => getChild<SRArchive>();

  /// Returns the archive of the star.
  @LuaExport("The archive of the star.")
  Future<SArchive?> get archive async => await getChild<SRArchive>()?.getRef();

  /// Returns the date the star was created.
  @LuaExport("The date the star was created.")
  DateTime get createdOn => DateTime.parse(get("date")!);

  /// Returns the constellation of the star.
  @LuaExport("The constellation of the star.")
  Constellation get constellation => getAncestors<Constellation>().first!;

  /// Returns true if the star is the root star.
  @LuaExport("True if the star is the root star.")
  bool get isRoot => getParent<Constellation>() != null;

  /// Returns true if the star is the current star.
  @LuaExport("True if the star is the current star.")
  bool get isCurrent => constellation.currentHash == hash;

  /// Returns true if the star is a single child.
  @LuaExport("True if the star is a single child.")
  bool get isSingleChild => getParent<Star>()?.getChildren<Star>().length == 1;

  /// Returns true if the star is a leaf.
  @LuaExport("True if the star is a leaf.")
  bool get isLeaf => getChildren<Star>().isEmpty;

  /// Returns true if the star is the stem of a branch.
  @LuaExport("True if the star is the stem of a branch.")
  bool get isStem => has("branch");

  /// Returns the branch name of the star.
  String get branchName => stem.get("branch")!;

  /// Returns the anchor star of the branch.
  Star get stem {
    final stem = has("branch")
        ? this
        : getAncestors<Star>(filter: (star) => star.has("branch")).first!;
    return stem;
  }

  /// Anchors the star, making it the stem of a new branch.
  @LuaExport("Anchors the star, making it the stem of a new branch.",
      name: "anchor")
  void makeStem(String name) {
    /// If the branch name already exists, throw an exception.
    if (constellation.getAllBranches().contains(name)) {
      throw Exception("Branch name already exists.");
    }
    set("branch", name);
  }

  /// Unanchors the star.
  @LuaExport("Unanchors the star.", name: "unanchor")
  void unmakeStem() {
    /// If the star is the root star, it cannot be unanchored, so it will do nothing and return.
    if (isRoot) return;
    set("branch", null);
  }

  /// Grows a new star from this star.
  /// Returns the new star.
  @LuaExport("Grows a new star from this star.")
  Future<Star> grow(String name, {String? branchName}) async {
    /// The new star.
    Star star;

    /// If there are no changes, create a new star with the exact same archive reference.
    /// If there are changes, create a new star with a new archive that references the old archive.
    if (!await checkForChanges()) {
      star =
          await StarCreator(name, generateUUID(), getChild<SRArchive>()!.copy())
              .create();
    } else {
      final newArchive = await SArchiveCreator.archiveFolder(
          constellation.path.resolvePath(),
          ref: await archive,
          includeList: constellation.globs);
      await kit.addRoot(newArchive);
      star =
          await StarCreator(name, generateUUID(), await newArchive.newIndent())
              .create();
    }
    addChild(star);

    if (branchName != null) {
      star.makeStem(branchName);
    }

    star.makeCurrent();

    return star;
  }

  /// Trims a star from the constellation.
  /// Will throw an exception if the star is the root star.
  /// The parent star will become current, the archive will be marked for deletion, and the star will be unparented.
  @LuaExport("Trims a star from the constellation.")
  Future<void> trim() async {
    if (isRoot) {
      throw Exception("Cannot trim root star!");
    }
    getParent<Star>()!.makeCurrent();
    if (getAncestors<Star>()
        .every((e) => e!.archiveRef!.hash != archiveRef!.hash)) {
      archiveRef!.markForDeletion();
    }

    unparent();
  }

  /// Gets a more detailed tree view of the star.
  Map<String, dynamic> tree() {
    return {
      ...summary(),
      "children": getChildren<Star>().map((child) => child!.tree()).toList(),
    };
  }

  /// Gets a summary of the star.
  @LuaExport("Gets a summary of the star.")
  Map<String, dynamic> summary() => {
        "name": name,
        "id": hash,
        "branch": branchName,
        "datetime": createdOn.toIso8601String(),
        "isRoot": isRoot,
        "isCurrent": isCurrent,
        "isSingleChild": isSingleChild,
        "isLeaf": isLeaf,
        "isStem": isStem,
      };

  /// Makes this star the current star.
  @LuaExport("Makes this star the current star.")
  void makeCurrent() {
    constellation.currentHash = hash;
  }

  @LuaExport(
      "Extracts the contents of this star, without needing to make it the current star.")
  Future<Stream<String>> checkout(String path) async =>
      await archive.then((e) async => e!.extract(path.resolvePath()));

  /// Checks for changes from the current star, and returns true if there are changes, false if there are none.
  @LuaExport("""Checks for changes from the current star.

Will return true if there are changes, false if there are none.""")
  Future<bool> checkForChanges() async {
    return await archive.then<bool>((value) => value!.checkForChanges(
        constellation.path.resolvePath(),
        includeList: constellation.globs));
  }

  @LuaExport(
      """Gets the star forward to this star X times, also known as children/descendants.
      
When encountering a fork, the top most star will be chosen.""")
  Star foward([int x = 1]) {
    Star star = this;
    while (x > 0) {
      star = star.getChild<Star>() ?? star;
      x--;
    }
    return star;
  }

  @LuaExport(
      "Gets the star backward to this star X times, also known as parents/ancestors.")
  Star backward([int x = 1]) {
    Star star = this;
    while (x > 0) {
      star = star.getParent<Star>() ?? star;
      x--;
    }
    return star;
  }

  @LuaExport("Gets the star above this star X times, also known as siblings.")
  Star above([int x = 1]) {
    Star star = this;
    while (x > 0) {
      star = star.getSiblingAbove() ?? star;
      x--;
    }
    return star;
  }

  @LuaExport("Gets the star below this star X times, also known as siblings.")
  Star below([int x = 1]) {
    Star star = this;
    while (x > 0) {
      star = star.getSiblingBelow() ?? star;
      x--;
    }
    return star;
  }

  @LuaExport("""Gets the child star at position X.
  
Will wrap around to the top if X is greater than the number of children.""")
  Star next([int x = 1]) {
    List<Star?> stars = getChildren<Star>();
    Star star = stars[(x - 1) % stars.length] ?? this;
    return star;
  }

  @LuaExport("Gets the most recent descendant star.")
  Star recent() {
    final stars = getDescendants<Star>();
    stars.sort((a, b) => a!.createdOn.compareTo(b!.createdOn));
    return stars.last ?? this;
  }
}

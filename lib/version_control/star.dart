import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/file_system.dart';
import 'package:arceus/version_control/constellation.dart';

part 'star.g.dart';

/// This class represents a star in a constellation.
/// A star is a node in the constellation tree, and contains a reference to an archive.
/// TODO: Add multi-user support, either by making a unique constellation for each user, or by associating the star with a user.
@SGen("star")
class Star extends SObject {
  @override
  get luaClassName => "Star";

  @override
  get exports => {
        "name": (Lua state) async {
          if (await state.isFromStack<String>(idx: 1)) {
            name = await state.getFromStack<String>(idx: 1);
          } else {
            return name;
          }
        },
        "hash": hash,
        "getArchive": (Lua state) async => await archive,
        "isRoot": isRoot,
        "isCurrent": (Lua state) => isCurrent,
        "isSingleChild": (Lua state) => isSingleChild,
      };

  @override
  bool get condenceBranch => true;

  Star(super._kit, super._node);

  /// Returns the name of the star.
  String get name => get("name") ?? "Initial Star";

  /// Sets the name of the star.
  set name(String value) => set("name", value);

  /// Returns the hash of the star.
  String get hash => get("hash")!;

  /// Sets the hash of the star.
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

  /// Grows a new star from this star.
  /// Returns the new star.
  Future<Star> grow(String name) async {
    final newArchive = await SArchiveCreator.archiveFolder(
        kit, constellation.path,
        ref: await archive);
    final star =
        await StarCreator(name, constellation.newStarHash(), newArchive.hash)
            .create(kit);
    addChild(star);
    constellation.currentHash = star.hash;
    return star;
  }

  /// Trims a star from the constellation.
  /// Will throw an exception if the star is the root star.
  /// The parent star will become current, the archive will be marked for deletion, and the star will be unparented.
  Future<void> trim() async {
    if (isRoot) {
      throw Exception("Cannot trim root star!");
    }
    await getParent<Star>()!.makeCurrent();
    await archive.then((e) => e!.markForDeletion());
    for (final archiveReference in getDescendants<SRArchive>()) {
      archiveReference!.markForDeletion();
    }
    unparent();
  }

  /// Makes this star the current star.
  Future<Stream<String>> makeCurrent() async {
    constellation.currentHash = hash;
    return await archive.then((e) async => e!.extract(constellation.path));
  }

  Future<bool> checkForChanges() async {
    return archive
        .then<bool>((value) => value!.checkForChanges(constellation.path));
  }
}

class StarCreator extends SCreator<Star> {
  final String name;
  final String hash;
  final String archiveHash;
  late SRArchive archive;

  StarCreator(this.name, this.hash, this.archiveHash);

  @override
  get beforeCreate => (kit) async {
        archive = await SRArchiveCreator(archiveHash).create(kit);
      };
  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("hash", hash);
        builder.attribute("date", DateTime.now().toIso8601String());
        builder.xml(archive.toXmlString());
      };
}

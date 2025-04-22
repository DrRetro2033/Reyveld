import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/file_system.dart';
import 'package:arceus/version_control/constellation.dart';

part 'star.g.dart';

/// This class represents a star in a constellation.
/// A star is a node in the constellation tree, and contains a reference to an archive.
/// TODO: Add multi-user support, either by making a unique constellation for each user, or by associating the star with a user.
@SGen("star")
class Star extends SObject {
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
    getParent<Star>()!.makeCurrent();
    await constellation.updateToCurrent();
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

class StarInterface extends SObjectInterface<Star> {
  @override
  String get className => "Star";

  @override
  get description => """
This class represents a star in a constellation.
A star is a point in time that represents a snapshot of an folder.
""";

  @override
  get exports => {
        "name": (lua) async {
          if (lua.state.isString(1)) {
            object!.name = await lua.getFromTop<String>();
          } else {
            return object!.name;
          }
        },
        "constellation": (_) => object!.constellation,
        "makeCurrent": (lua) async {
          bool updateFolder = false;
          if (lua.state.isBoolean(1)) {
            updateFolder = await lua.getFromTop<bool>();
          }
          object!.makeCurrent();
          if (updateFolder) {
            await object!.constellation.updateToCurrent();
          }
        },
        "getArchive": (lua) async => await object!.archive,
        "trim": (state) async => await object!.trim(),
        "grow": (state) async =>
            await object!.grow(await state.getFromTop<String>()),
        "isRoot": (_) => object!.isRoot,
        "isCurrent": (_) => object!.isCurrent,
        "isSingleChild": (_) => object!.isSingleChild,
        "forward": (state) async {
          int x = await state.getFromTop<int?>() ?? 1;
          Star star = object!;
          while (x > 0) {
            star = star.getChild<Star>() ?? star;
            x--;
          }
          return star;
        },
        "backward": (state) async {
          int x = await state.getFromTop<int?>() ?? 1;
          Star star = object!;
          while (x > 0) {
            star = star.getParent<Star>() ?? star;
            x--;
          }
          return star;
        },
        "above": (state) async {
          int x = await state.getFromTop<int?>() ?? 1;
          Star star = object!;
          while (x > 0) {
            star = star.getSiblingAbove<Star>() ?? star;
            x--;
          }
          return star;
        },
        "below": (state) async {
          int x = await state.getFromTop<int?>() ?? 1;
          Star star = object!;
          while (x > 0) {
            star = star.getSiblingBelow<Star>() ?? star;
            x--;
          }
          return star;
        },
        "next": (state) async {
          int x = await state.getFromTop<int?>() ?? 1;
          List<Star?> stars = object!.getChildren<Star>();
          Star star = stars[(x - 1) % stars.length] ?? object!;
          return star;
        },
        "depth": (state) async {
          int x = await state.getFromTop<int?>() ?? 1;
          return object!.constellation.root
                  .getDescendants<Star>(filter: (e) => e.getDepth() == x)[0] ??
              object!.constellation.root.getDescendants<Star>().last ??
              object!.constellation.root;
        }
      };
}

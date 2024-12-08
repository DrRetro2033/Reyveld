import 'package:archive/archive_io.dart';
import 'dart:convert';
import 'constellation.dart';
import 'users.dart';
import 'dart:io';
import 'dossier.dart';

/// # `class` Star
/// ## Represents a star in the constellation.
/// Stars can be thought as an analog to Git commits.
/// They are saved as a `.star` file in the constellation's directory.
/// A `.star` file literally is just a ZIP file, so you can open them in 7Zip or WinRAR.
class Star {
  Constellation constellation; // The constellation the star belongs to.
  Starmap get starmap =>
      constellation.starmap!; // The starmap of the constellation.

  String? name; // The name of the star.
  String? hash; // The hash of the star.
  DateTime? createdAt; // The time the star was created.
  String? get _parentHash =>
      constellation.starmap?.parentMap[hash]; // The hash of the parent star.
  String? _userHash; // The hash of the user who this star belongs to.
  User? get user => constellation.userIndex
      ?.getUser(_userHash!); // The user who this star belongs to.
  Star? get parent {
    if (_parentHash == null) return null;
    return Star(constellation, hash: _parentHash);
  } // Gets the parent star.

  /// # `List<Star>` children
  /// ## Returns a list of all children of this star from the starmap contained in the constellation.
  List<Star> get children => starmap.getChildren(this);

  /// # `int` childIndex
  /// ## Returns the index of this star in its parent's children list.
  int get childIndex =>
      parent != null ? parent!.children.indexWhere((e) => e.hash == hash) : 0;

  /// # `int` siblingCount
  /// ## Returns the number of siblings of this star.
  int get siblingCount => parent != null ? parent!.children.length - 1 : 0;

  /// # `bool` singleChild
  /// ## Does this star only have a single child?
  bool get singleChild => children.length == 1;

  /// # `bool` hasNoChildren
  /// ## Does this star have no children?
  bool get hasNoChildren => children.isEmpty;

  /// # `bool` hasChildren
  /// ## Does this star have children?
  bool get hasChildren => children.isNotEmpty;

  /// # `bool` isCurrent
  /// ## Is this star the current star?
  bool get isCurrent => hash == constellation.starmap?.currentStarHash;

  /// # `bool` isRoot
  /// ## Is this star the root star?
  bool get isRoot => hash == constellation.starmap?.rootHash;

  /// # `bool` isSingleChild
  /// ## Is this star a single child?
  bool get isSingleChild => parent != null ? parent!.singleChild : false;

  /// # `Star`(`Constellation` constellation, {`String?` name, `String?` hash, `User?` user})
  /// ## Creates a new star.
  /// When creating a new star, call this constructor with the arguments `name` and `user`.
  /// When loading a already existing star, call this constructor with the argument `hash`.
  Star(
    this.constellation, {
    this.name,
    this.hash,
    User? user,
  }) {
    constellation.starmap?.initEntry(hash ?? "");
    if (name != null && user != null) {
      _userHash = user.hash;
      _create();
    } else if (hash != null) {
      _load();
    } else {
      throw Exception("Star must have a name and user, or a hash.");
    }
  }

  /// # `void` _create()
  /// ## Creates the star and saves it to the constellation.
  /// It also adds the star to the constellation's starmap.
  void _create() {
    createdAt = DateTime.now();
    hash = constellation.generateUniqueStarHash();
    ZipFileEncoder archive = ZipFileEncoder();
    archive.create(constellation.getStarPath(hash!));
    String content = _generateStarFileData();
    archive.addArchiveFile(ArchiveFile("star", content.length, content));
    for (FileSystemEntity entity in constellation.directory.listSync()) {
      if (entity is File) {
        if (entity.path.endsWith(".star")) {
          continue;
        }
        archive.addFile(entity);
      } else if (entity is Directory) {
        if (entity.path.endsWith(".constellation")) {
          continue;
        }
        archive.addDirectory(entity);
      }
    }
    archive.closeSync();
  }

  /// # `String` createChild(`String` name)
  /// ## Creates a new star with the given name.
  /// It returns the hash of the new star.
  String createChild(String name, {bool force = false}) {
    if (!force && !constellation.checkForDifferences()) {
      throw Exception(
          "Cannot create a child star when there are no differences. Please make changes and try again.");
    }
    Star star = Star(constellation,
        name: name, user: constellation.userIndex?.getHostUser());
    constellation.starmap?.addRelationship(this, star);
    constellation.starmap?.currentStar = star;
    constellation.save();
    return star.hash!;
  }

  /// # `Star` getParentStar()
  /// ## Returns the parent star.
  Star? getParentStar() {
    if (_parentHash == null) return null;
    return Star(constellation, hash: _parentHash);
  }

  /// # `void` _load()
  /// ## Loads the star from disk.
  void _load() {
    Archive archive = getArchive();
    ArchiveFile? file = archive.findFile("star");
    _fromStarFileData(utf8.decode(file!.content));
    archive.clearSync();
  }

  /// # `void` _extract()
  /// ## Extracts the star from the archive.
  /// This is used when jumping to an existing star.
  void _extract() {
    Archive archive = getArchive();
    constellation.clear();
    for (ArchiveFile file in archive.files) {
      if (file.isFile && file.name != "star") {
        final x = File("${constellation.path}/${file.name}");
        if (!x.existsSync()) {
          x.createSync(recursive: true);
        }
        x.writeAsBytesSync(file.content);
      }
    }
    archive.clearSync();
  }

  /// # `void` makeCurrent()
  /// ## Makes the star the current star in the constellation.
  void makeCurrent() {
    _extract();
    constellation.starmap?.currentStar = this;
    constellation.save();
  }

  /// # `Archive` getArchive()
  /// ## Returns the archive of the star.
  /// ALWAYS, ALWAYS, ALWAYS call `clearSync()` on the archive after using it.
  /// If you don't, then trimming the star will not work, and will throw an access error.
  Archive getArchive() {
    final inputStream = InputFileStream(constellation.getStarPath(hash!));
    final archive = ZipDecoder().decodeBuffer(inputStream);
    return archive;
  }

  /// # `Plasma` getPlasma(`String` pathOfFileInStar)
  /// ## Returns a new `Plasma` for a file at path relative to the star.
  Plasma getPlasma(String pathOfFileInStar) {
    return Plasma.fromStar(this, pathOfFileInStar);
  }

  /// # `void` _fromStarFileData(`String` data)
  /// ## Converts the JSON `data` into usable info about a star.
  /// JSON data is stored in a file named `star` inside a `.star` file.
  void _fromStarFileData(String data) {
    fromJson(jsonDecode(data));
  }

  /// # `String` _generateStarFileData()
  /// ## Generates the data for the `star` file inside the `.star`.
  /// Inside a `.star` file, there is a single file just called `star` with no extension.
  /// This file contains the star's data in JSON format.
  String _generateStarFileData() {
    return jsonEncode(toJson());
  }

  /// # `Star` getMostRecentStar()
  /// ## Returns the most recent star in the constellation.
  /// If the star has no children, it returns itself.
  Star getMostRecentStar() {
    if (starmap.getChildren(this).isEmpty) {
      return this;
    }
    if (starmap.getChildren(this).length == 1) {
      return starmap.getChildren(this)[0].getMostRecentStar();
    }
    Star mostRecentStar = starmap.getChildren(this)[0];
    for (Star child in starmap.getChildren(this)) {
      if (child.createdAt!.isAfter(mostRecentStar.createdAt!)) {
        mostRecentStar = child;
      }
    }
    return mostRecentStar.getMostRecentStar();
  }

  /// # `List<Star>` getDescendants()
  /// ## Returns a list of all descendants of the star.
  /// The list will be empty if the star has no descendants.
  List<Star> getDescendants() {
    List<Star> descendants = [];
    for (Star child in children) {
      descendants.add(child);
      descendants.addAll(child.getDescendants());
    }
    return descendants;
  }

  /// # `List<Star>` getAncestors()
  /// ## Returns a list of all ancestors of the star.
  /// The list will be empty if the star has no ancestors, which usually means it is the root star.
  List<Star> getAncestors() {
    List<Star> ancestors = [];
    Star? parent = this.parent;
    while (parent != null) {
      ancestors.add(parent);
      parent = parent.parent;
    }
    return ancestors;
  }

  bool isChildOf(Star star) =>
      star.children.any((element) => element.hash == hash);

  bool isParentOf(Star star) =>
      children.any((element) => element.hash == star.hash);

  bool isDescendantOf(Star star) {
    return getAncestors().contains(star);
  }

  bool isAncestorOf(Star star) {
    return getDescendants().contains(star);
  }

  /// # `void` trim()
  /// ## Trims the star and all of its children.
  void trim() {
    for (Star child in children) {
      child.trim();
    }
    starmap.sterilizeStar(this);
    _delete();
  }

  /// # `void` _delete()
  /// ## Deletes the star from disk.
  /// DO NOT USE THIS DIRECTLY, AS IT WILL CORRUPT THE CONSTELLATION IF NOT TRIMED PROPERLY.
  /// Use the `trim()` method instead.
  void _delete() {
    File(constellation.getStarPath(hash!)).deleteSync();
  }

  /// # `void` fromJson(`Map<String, dynamic>` json)
  /// ## Converts the JSON data into a `Star` object.
  void fromJson(Map<String, dynamic> json) {
    name = json["name"];
    createdAt = DateTime.tryParse(json["createdAt"]);
    _userHash = json["user"];
  }

  /// # `Map<String, dynamic>` toJson()
  /// ## Converts the `Star` object into a JSON object.
  Map<String, dynamic> toJson() =>
      {"name": name, "createdAt": createdAt.toString(), "user": _userHash};

  @override
  String toString() => hash!;

  /// # `String` getDisplayName()
  /// ## Returns the name of the star, with a ✨ if it is the current star.
  /// This is used when printing the star to the terminal.
  String getDisplayName() {
    if (isCurrent) {
      return "${name!} ✨";
    } else {
      return name!;
    }
  }

  void removeChild(Star star) {
    constellation.starmap?.childMap[hash!]!.remove(star.hash!);
  }

  /// # `Star` getChild(`int` index)
  /// ## Returns the child star at the given index.
  ///
  Star getChild(int index) {
    if (hasNoChildren) {
      return this; // A failsafe in the case a star does not have any children.
    }
    // A safe guard for if any logic breaks in another function, and a index is out of bounds.
    if (index < 0) index = 0;
    if (index >= children.length) index = children.length - 1;

    return Star(constellation, hash: starmap.childMap[hash!]![index]);
  }

  /// # `int` getDepth()
  /// ## Returns the depth of the star in the starmap.
  int getDepth() {
    return getAncestors().length;
  }

  /// # `int` getIndex()
  /// ## Returns the index of the star in the starmap.
  int getIndex() {
    return starmap
        .getStarsAtDepth(getDepth())
        .indexWhere((star) => star.hash == hash);
  }

  /// # `List<Star>` getDeepSiblings()
  /// ## Returns a list of all of the siblings at the same depth as this star, including this star.
  List<Star> getDeepSiblings() {
    int depth = getDepth(); // Get the depth of this star.
    int index =
        getIndex(); // Get the index of this star (i.e. where is it relative to its siblings?)
    while (depth > 0) {
      // While the depth is greater than 0 (i.e. not the root star)
      if (starmap.existBesideCoordinates(depth, index)) {
        // Are there siblings right next to this star at this depth? If so, then we are done.
        break;
      }
      depth--;
    }
    List<Star> stars = starmap.getStarsAtDepth(depth);
    stars.removeAt(index);
    stars.insert(index, this);
    return stars;
  }

  Star getSibling({int? above, int? below}) {
    if (above == null && below == null) {
      return this;
    }
    above = above == 0 ? 1 : above;
    below = below == 0 ? 1 : below;
    List<Star> siblings = getDeepSiblings();
    int offset = above ??
        -below!; // If above is null, then below is not null. above will add to the index, while below will subtract.
    return siblings[(getIndex() + offset) %
        siblings
            .length]; // I ❤️ modulo. It's almost magic how easily it can wrap a index around to a vaild range.
  }
}

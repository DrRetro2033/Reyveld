import 'package:arceus/widget_system.dart';
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
  /// # [Constellation] constellation
  /// ## The constellation this star belongs to.
  Constellation constellation;

  /// # [Starmap] get starmap
  /// ## Returns the starmap of the constellation.
  Starmap get starmap => constellation.starmap!;

  /// # String? name
  /// ## The name of the star.
  late String name;

  /// # String? hash
  /// ## The hash of the star.
  late String hash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Star && runtimeType == other.runtimeType && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  /// # DateTime? createdAt
  /// ## The time the star was created.
  late DateTime? createdAt;

  /// # String? _userHash
  /// ## The hash of the user who this star belongs to.
  late String? _userHash;

  late Set<String> tags;

  /// # [User]? get user
  /// ## Returns the user who this star belongs to.
  User? get user => constellation.userIndex.getUser(_userHash!);

  /// # [Star]? get parent
  /// ## Returns the parent of this star from the starmap contained in the constellation.
  /// Will return the root star if this star is the root star.
  Star get parent => isRoot ? this : starmap.getParent(this) ?? this;

  /// # List<[Star]> children
  /// ## Returns a list of all children of this star from the starmap contained in the constellation.
  List<Star> get children => starmap.getChildren(this);

  /// # int childIndex
  /// ## Returns the index of this star in its parent's children list.
  int get childIndex => parent.children.indexWhere((e) => e == this);

  /// # int siblingCount
  /// ## Returns the number of siblings of this star.
  int get siblingCount => getDeepSiblings(includeSelf: false).length;

  /// # bool singleChild
  /// ## Does this star only have a single child?
  bool get hasSingleChild => children.length == 1;

  Star get singleChild => children.first;

  /// # bool hasNoChildren
  /// ## Does this star have no children?
  bool get hasNoChildren => children.isEmpty;

  /// # bool hasChildren
  /// ## Does this star have children?
  bool get hasChildren => children.isNotEmpty;

  /// # bool isCurrent
  /// ## Is this star the current star?
  bool get isCurrent => this == constellation.starmap?.currentStar;

  /// # bool isRoot
  /// ## Is this star the root star?
  bool get isRoot => this == constellation.starmap?.root;

  /// # bool isSingleChild
  /// ## Is this star a single child?
  bool get isSingleChild => parent.hasSingleChild;

  /// # Star([Constellation] constellation, {String? name, String? hash, [User]? user})
  /// ## Creates a new star.
  /// When creating a new star, call this constructor with the arguments name and user.
  /// When loading a already existing star, call this constructor with the argument hash.
  Star(
    this.constellation, {
    String? name,
    String? hash,
    User? user,
  }) {
    if (name != null) {
      this.name = name;
    }
    if (hash != null) {
      this.hash = hash;
    }
    constellation.starmap?.initEntry(hash ?? "");
    if (name != null) {
      if (user != null) {
        _userHash = user.hash;
      } else {
        _userHash = constellation.loggedInUser.hash;
      }
      _create();
    } else if (hash != null) {
      _load();
    } else {
      throw Exception("Star must have a name and user, or a hash.");
    }
  }

  /// # void _create()
  /// ## Creates the star and saves it to the constellation.
  /// It also adds the star to the constellation's starmap.
  void _create() {
    createdAt = DateTime.now();
    hash = constellation.generateUniqueStarHash();
    tags = {};
    ZipFileEncoder archive = ZipFileEncoder();
    archive.create(constellation.getStarPath(hash));
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

  /// # String createChild(String name)
  /// ## Creates a new star with the given name.
  /// It returns the hash of the new star.
  String createChild(String name, {bool force = false, User? user}) {
    if (!force && !constellation.checkForDifferences()) {
      print(
          "Cannot create a new child star, as there are no changes to the constellation. If you want to grow anyway, use the '--force' flag.");
      return "";
    }
    Star star = Star(constellation, name: name, user: user ?? this.user);
    constellation.starmap?.addRelationship(this, star);
    star.makeCurrent(save: false);
    constellation.save();
    print("Created child star: ${star.name}");
    return star.hash;
  }

  /// # void _load()
  /// ## Loads the star from disk.
  void _load() {
    Archive archive = getArchive();
    ArchiveFile? file = archive.findFile("star");
    String content = utf8.decode(file!.content);
    archive.clearSync();
    file.closeSync();
    _fromStarFileData(content);
  }

  /// # void _extract()
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

  /// # void recover()
  /// ## Extracts everything from the star, without interacting with the constellation and its starmap.
  /// Used for recovering data from corrupted constellation.
  void recover() {
    _extract();
  }

  /// # void makeCurrent()
  /// ## Makes the star the current star in the constellation.
  /// It also saves the constellation.
  void makeCurrent({bool save = true, bool login = true}) {
    _extract();
    constellation.starmap!.currentStar = this;
    if (login) constellation.loggedInUser = user!;
    if (save) constellation.save();
  }

  /// # Archive getArchive()
  /// ## Returns the archive of the star.
  /// ALWAYS, ALWAYS, ALWAYS call [clearSync] on the archive object after using it.
  /// If you don't, then trimming the star will not work, and will throw an access error.
  Archive getArchive() {
    final inputStream = InputFileStream(constellation.getStarPath(hash));
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
    Map<String, dynamic> json = jsonDecode(data);
    bool resave =
        false; // Resave the star if any details are missing, with the new details.
    if (!json.containsKey("tags")) {
      resave = true;
    }
    _fromJson(json);
    if (resave) {
      save();
    }
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
    Star parent = this.parent;
    while (parent.parent != parent) {
      ancestors.add(parent);
      parent = parent.parent;
    }
    return ancestors;
  }

  /// # bool isChildOf([Star] star)
  /// ## Is the star a child of the given star?
  bool isChildOf(Star star) => star.children.any((element) => element == this);

  /// # bool isParentOf([Star] star)
  /// ## Is the star a parent of the given star?
  bool isParentOf(Star star) => children.contains(star);

  /// # bool isDescendantOf([Star] star)
  /// ## Is the star a descendant of the given star?
  bool isDescendantOf(Star star) {
    return getAncestors().contains(star);
  }

  /// # bool isAncestorOf([Star] star)
  /// ## Is the star an ancestor of the given star?
  bool isAncestorOf(Star star) {
    return getDescendants().contains(star);
  }

  /// # void trim()
  /// ## Trims the star and all of its children safely and deletes the star from disk.
  void trim() {
    for (Star child in children) {
      child.trim();
    }
    starmap.sterilizeStar(this);
    _delete();
  }

  /// # void _delete()
  /// ## Deletes the star from disk.
  /// DO NOT USE THIS DIRECTLY, AS IT WILL CORRUPT THE CONSTELLATION IF NOT TRIMED PROPERLY.
  /// Use the [trim] method instead.
  void _delete() {
    File(constellation.getStarPath(hash)).deleteSync();
  }

  /// # void fromJson(Map<String, dynamic> json)
  /// ## Converts the JSON data into a [Star] object.
  void _fromJson(Map<String, dynamic> json) {
    name = json["name"];
    createdAt = DateTime.tryParse(json["createdAt"]);
    _userHash = json["user"];
    tags = Set<String>.from(json["tags"] ?? {});
  }

  /// # Map<String, dynamic> toJson()
  /// ## Converts the [Star] object into a JSON object.
  Map<String, dynamic> toJson() => {
        "name": name,
        "createdAt": createdAt.toString(),
        "user": _userHash,
        "tags": tags.toList(),
      };

  void save() {
    Archive archive = getArchive();
    ZipFileEncoder archiveEncoder = ZipFileEncoder();
    archiveEncoder.create(constellation.getStarPath(hash, temp: true));
    for (ArchiveFile file in archive.files) {
      if (file.name == "star") {
        String content = _generateStarFileData();
        archiveEncoder
            .addArchiveFile(ArchiveFile('star', content.length, content));
      } else {
        archiveEncoder.addArchiveFile(file);
      }
      file.closeSync();
    }
    archive.clearSync();
    archiveEncoder.closeSync();

    File(constellation.getStarPath(hash)).deleteSync();
    File(constellation.getStarPath(hash, temp: true))
        .renameSync(constellation.getStarPath(hash));
  }

  /// # `String` toString()
  /// ## Returns the hash of the star.
  @override
  String toString() => hash;

  /// # String getDisplayName()
  /// ## Returns the name of the star for displaying.
  /// This is used when printing the star to the terminal.
  /// The name will end with a ✨ if it's the current star.
  /// It will also show a user badge, and the first two tags attached to the star.
  String getDisplayName() {
    int tagsToDisplay = 2;
    List<Badge> badges = [];
    for (String tag in tags) {
      if (tagsToDisplay == 0) {
        break;
      }
      badges.add(Badge(tag));
      tagsToDisplay--;
    }
    Badge userBadge = user!.badge;
    final displayName =
        "$name $userBadge ${badges.isNotEmpty ? badges.join(" ") : ""} ${isCurrent ? "✨" : ""}";
    return displayName;
  }

  /// # [Star] getChild(int index)
  /// ## Returns the child star at the given index.
  Star getChild(int index) {
    if (hasNoChildren) {
      return this; // A failsafe in the case a star does not have any children.
    }
    // A safe guard for if any logic breaks in another function, and an index is out of bounds.
    if (index < 0) index = 0;
    if (index >= children.length) index = children.length - 1;

    return children[index];
  }

  /// # int getDepth()
  /// ## Returns the depth of the star in the starmap.
  int getDepth() {
    return getAncestors().length + 1;
  }

  /// # int getIndex()
  /// ## Returns the index of the star in the starmap.
  int getIndex() {
    return starmap.getStarsAtDepth(getDepth()).indexOf(this);
  }

  /// # List<[Star]> getDeepSiblings()
  /// ## Returns a list of all of the siblings at the same depth as this star, including this star.
  List<Star> getDeepSiblings({bool includeSelf = true}) {
    int depth = getDepth(); // Get the depth of this star.
    while (depth > 0) {
      // While the depth is greater than 0 (i.e. not the root star)
      if (starmap.moreExistAtDepth(depth, this)) {
        // Are there siblings at this depth?
        break;
      }
      depth--;
    }
    List<Star> stars = starmap.getStarsAtDepth(depth);
    if (!includeSelf) {
      stars.removeWhere(
          (element) => element == this || element.isAncestorOf(this));
    }
    return stars;
  }

  Star getSibling({int? above, int? below}) {
    if (above == null && below == null) {
      return this;
    }
    List<Star> siblings = getDeepSiblings();
    int offset = below ??
        -above!; // If above is null, then below is not null. above will add to the index, while below will subtract.
    int index = siblings.indexWhere((e) => e == this || e.isAncestorOf(this));
    return siblings[(index + offset) %
        siblings
            .length]; // I ❤️ modulo. It's almost magic how easily it can wrap a index around to a valid range! I just wish I could use it more often.
  }

  bool addTag(String tag) {
    if (tags.add(tag)) {
      save();
      return true;
    } else {
      return false;
    }
  }

  bool removeTag(String tag) {
    if (tags.remove(tag)) {
      save();
      return true;
    } else {
      return false;
    }
  }

  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  void clearTags() {
    tags.clear();
    save();
  }
}

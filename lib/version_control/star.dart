import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/widget_system.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/version_control/users.dart';
import 'dart:io';
import 'package:arceus/version_control/plasma.dart';

/// # class StarFile
/// ## Represents a star file, which is a ZIP file containing the contents and details of a star.
/// TODO: Change every other class that uses a JSON to store details to use this design pattern, as it is more efficient, safe, and easier to understand.
class StarFile {
  final String path;

  Map<String, dynamic>?
      _details; // the last updated details of the star. used to improve performance by not redoing the same operation, when nothing has changed.
  String?
      _checksum; // the checksum of the content of the star. also used to improve performance.

  String get name => _getDetails()["name"];
  set name(String name) => _saveDetails({"name": name});
  DateTime get createdAt => DateTime.parse(_getDetails()["createdAt"]);
  String get userHash => _getDetails()["user"];
  set userHash(String hash) => _saveDetails({"user": hash});
  Set<String> get tags =>
      (_getDetails()["tags"] as List<dynamic>).toSet().cast<String>();
  set tags(Set<String> tags) => _saveDetails({"tags": tags.toList()});

  /// # DateTime get [lastModified]
  /// ## Returns the last modified date of the star file.
  /// If the last modified date is not set in details, it returns the creation date.
  /// This is always updated when [_saveDetails] is called.
  DateTime get lastModified {
    if (!_getDetails().containsKey("lastModified")) {
      return createdAt;
    } else {
      return DateTime.parse(_getDetails()["lastModified"]);
    }
  }

  /// # String get [hash]
  /// ## Returns the hash of the star file.
  /// The hash is the filename of the star file without the extension.
  String get hash => path.getFilename(withExtension: false);

  StarFile(this.path);

  factory StarFile.create(String path, String compressPath,
      String name, String userHash) {
    Map<String, dynamic> details = {
      "name": name,
      "createdAt": DateTime.now().toString(),
      "user": userHash,
      "tags": <String>[],
    };
    ZipFileEncoder archive = ZipFileEncoder();
    archive.create(path);
    String content = jsonEncode(details);
    archive.addArchiveFile(ArchiveFile("star", content.length, content));
    for (FileSystemEntity entity in Directory(compressPath).listSync()) {
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
    Arceus.talker.info("Created star file '$path'.");
    return StarFile(path);
  }

  /// # void extract()
  /// ## Extracts the star from the archive.
  /// This is used when jumping to an existing star.
  bool extract(String extractPath) {
    Archive archive = getArchive();
    bool finishedSuccessfully = true;
    for (ArchiveFile file in archive.files) {
      if (file.isFile && file.name != "star") {
        final x = File("$extractPath/${file.name}");
        if (!x.existsSync()) {
          x.createSync(recursive: true);
        }
        try {
          x.writeAsBytesSync(file.content);
        } catch (e) {
          Arceus.talker.error(
              "Failed to extract file '${path.getFilename()}'. Most likely due to it being used in another program.");
          finishedSuccessfully = false;
          continue;
        }
      }
    }
    archive.clearSync();
    if (!finishedSuccessfully) {
      Arceus.talker.error(
          "Failed to properly extract star file '${path.getFilename()}'!");
      return false;
    }
    Arceus.talker
        .info("Extracted star file '${path.getFilename()}' to '$extractPath'.");
    return true;
  }

  /// # void _saveDetails(Map<String, dynamic> details)
  /// ## Saves the details of the star.
  /// This is used when updating the details of the star to disk.
  void _saveDetails(Map<String, dynamic> details) {
    final content = _getDetails();
    content.addAll(details);

    content["lastModified"] = DateTime.now().toString(); // update last modified
    Archive archive = getArchive(); // get archive from star
    ZipFileEncoder archiveEncoder = ZipFileEncoder(); // create new encoder
    final tempPath = "$path.temp"; // create temp path for star file.
    archiveEncoder.create(tempPath); // create new temp archive
    final contentString = jsonEncode(content); // encode content
    archiveEncoder.addArchiveFile(ArchiveFile(
        'star', contentString.length, contentString)); // add star file
    for (ArchiveFile file in archive.files) {
      // add all other files
      if (file.name == "star") {
        continue;
      } else {
        archiveEncoder.addArchiveFile(file);
      }
      file.closeSync(); // close file
    }
    archive.clearSync(); // clear archive safely
    archiveEncoder.closeSync(); // close the encoder

    File(path).deleteSync(); // delete old star file
    File(tempPath).renameSync(path); // rename temp file to path.

    _details = content;
    _checksum = null;

    Arceus.talker.info("Updated details of star file '${path.getFilename()}'.");
  }

  /// # Map<String, dynamic> _getDetails()
  /// ## Gets the details of the star.
  /// If the details haven't been loaded yet, it loads them from the "star" file in the archive.
  /// The details are cached to prevent disk I/O from being needed every time the details are accessed.
  Map<String, dynamic> _getDetails() {
    if (_details == null) {
      Archive archive = getArchive();
      ArchiveFile? file = archive.findFile("star");
      String content = utf8.decode(file!.content);
      archive.clearSync();
      file.closeSync();
      _details = jsonDecode(content);
    }
    return _details!;
  }

  /// # [Archive] getArchive()
  /// ## Returns the archive of the star.
  /// ALWAYS, ALWAYS, ALWAYS call [Archive.clearSync] on the archive object after using it.
  /// If you don't, then trimming a star will not work, and will throw an access error.
  Archive getArchive() {
    final inputStream = InputFileStream(path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    // Arceus.talker.info("Got archive of star file '${path.getFilename()}'.");
    return archive;
  }

  bool addTag(String tag) {
    Set<String> newTags = {...tags};
    if (newTags.add(tag)) {
      _saveDetails({"tags": newTags.toList()});
      return true;
    } else {
      return false;
    }
  }

  bool removeTag(String tag) {
    Set<String> newTags = {...tags};
    if (newTags.remove(tag)) {
      _saveDetails({"tags": newTags.toList()});
      return true;
    } else {
      return false;
    }
  }

  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  void clearTags() {
    Set<String> newTags = {...tags};
    newTags.clear();
    _saveDetails({"tags": newTags.toList()});
  }

  /// # String getDisplayName()
  /// ## Returns the formatted name of the star file for displaying.
  /// This is used when printing details about a star file to the terminal.
  String getDisplayName() {
    int tagsToDisplay = 2;
    List<Badge> badges = [];
    for (String tag in tags) {
      if (tagsToDisplay == 0) {
        break;
      }
      badges.add(Badge("🏷️$tag"));
      tagsToDisplay--;
    }
    Badge userBadge = Arceus.userIndex.getUser(userHash).badge;
    Badge dateBadge = Badge(
        '📅${createdAt.year}/${createdAt.month}/${createdAt.day}',
        badgeColor: "grey",
        textColor: "white");
    Badge timeBadge = Badge(
        '🕒${createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour >= 12 ? 'PM' : 'AM'}',
        badgeColor: "grey",
        textColor: "white");
    final displayName =
        "$name $userBadge$dateBadge$timeBadge${badges.isNotEmpty ? badges.join(" ") : ""}";
    return displayName;
  }

  /// # String getChecksum()
  /// ## Returns the checksum of the content of the star file.
  /// Used for checking to see if star files have the same hash, but different content.
  String getChecksum({bool excludeDetails = true}) {
    if (_checksum == null) {
      List<int> checksums = [];
      Archive archive = getArchive();
      for (ArchiveFile file in archive.files) {
        if (file.isFile) {
          if (excludeDetails && file.name == "star") {
            continue;
          }
          checksums.add(file.crc32!);
        }
        file.closeSync();
      }
      archive.clearSync();
      _checksum = checksums.map((crc32) => crc32.toRadixString(16)).join();
    }
    return _checksum!;
  }

  /// # String copyTo(Constellation constellation)
  /// ## Copies the star file to the given constellation and returns the new hash of the star.
  /// Used for unpacking constellation packages.
  String copyTo(Constellation constellation) {
    String newHash =
        hash; // The hash the star file will have when copied to the constellation.
    if (constellation.doesStarExist(hash)) {
      // Does a star already exists with the same hash?

      // Check if the star file has different content. If so, generate a new hash.
      if (getChecksum() != Star(constellation, hash).file.getChecksum()) {
        newHash = constellation.generateUniqueStarHash();
      } else {
        // If the star files do have the same content, check last date modified.
        final oldStar = StarFile(constellation.getStarPath(hash));

        if (lastModified.isAfter(oldStar.lastModified)) {
          // If the new star file is newer, delete the old star file to replace it.
          File(constellation.getStarPath(hash)).deleteSync();
        } else {
          // If the old star file is newer, do not copy new file over.
          return hash;
        }
      }
    }
    final file = File(path);
    file.copySync(constellation.getStarPath(newHash));
    return newHash;
  }
}

/// # class Star
/// ## Represents a star in the constellation.
/// Stars can be thought as an analog to Git commits.
/// They are saved as a `.star` file in the constellation's directory.
/// A `.star` file literally is just a ZIP file, so you can open them in 7Zip or WinRAR.
class Star {
  /// # [Constellation] constellation
  /// ## The constellation this star belongs to.
  final Constellation constellation;

  /// # [Starmap] get starmap
  /// ## Returns the starmap of the constellation.
  Starmap get starmap => constellation.starmap;

  /// # String hash
  /// ## The hash of the star.
  final String hash;

  /// # String? name
  /// ## The name of the star.
  String get name => file.name;

  set name(String value) => file.name = value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Star && runtimeType == other.runtimeType && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  /// # DateTime? createdAt
  /// ## The time the star was created.
  DateTime get createdAt => file.createdAt;

  /// # String? _userHash
  /// ## The hash of the user who this star belongs to.
  String get _userHash => file.userHash;

  /// # [User]? get user
  /// ## Returns the user who this star belongs to.
  User get user => constellation.userIndex.getUser(_userHash);

  set user(User value) => file.userHash = value.hash;

  Set<String> get tags => file.tags;

  set tags(Set<String> value) => file.tags = value;

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
  bool get isCurrent => this == constellation.starmap.currentStar;

  /// # bool isRoot
  /// ## Is this star the root star?
  bool get isRoot => this == constellation.starmap.root;

  /// # bool isSingleChild
  /// ## Is this star a single child?
  bool get isSingleChild => parent.hasSingleChild;

  StarFile get file => StarFile(constellation.getStarPath(hash));

  /// # Star([Constellation] constellation, {String? name, String? hash, [User]? user})
  /// ## Creates a new star.
  /// When creating a new star, call this constructor with the arguments name and user.
  /// When loading an already existing star, call this constructor with the argument hash.
  Star(this.constellation, this.hash);

  /// # void _create()
  /// ## Creates the star and saves it to the constellation.
  /// It also adds the star to the constellation's starmap.
  factory Star.create(Constellation constellation, String name, {User? user}) {
    final hash = constellation.generateUniqueStarHash();
    StarFile.create(constellation.getStarPath(hash), constellation.path,
        name,
        user?.hash ?? Arceus.userIndex.getHostUser().hash);
    Arceus.talker.info(
        "Created star '$name' with hash '$hash' in constellation '${constellation.name}' at path '${constellation.path}'.");
    return Star(constellation, hash);
  }

  /// # Star copyTo(Constellation newConstellation)
  /// ## Copies the star to the given constellation and returns the new star.
  /// It also adds the star to the new constellation's starmap.
  Star copyTo(Constellation newConstellation) {
    final newHash = file.copyTo(newConstellation);
    final star = Star(newConstellation, newHash);
    newConstellation.starmap.addRelationship(parent, star, save: false);
    return star;
  }

  /// # String createChild(String name)
  /// ## Creates a new star with the given name.
  /// It returns the hash of the new star.
  Star createChild(String name, {bool force = false, User? user}) {
    if (!force && !constellation.checkForDifferences()) {
      print(
          "Cannot create a new child star, as there are no changes to the constellation. If you want to grow anyway, use the '--force' flag.");
      return this;
    }
    Star star = Star.create(constellation, name, user: user);
    star.tags = tags;
    constellation.starmap.addRelationship(this, star);
    if (!star.makeCurrent(save: false)) {
      Arceus.talker.info("Was unable to make new star current.");
    }
    constellation.save();
    return star;
  }

  bool resync() {
    return file.extract(constellation.path);
  }

  /// # void makeCurrent()
  /// ## Makes the star the current star in the constellation.
  /// It also saves the constellation.
  bool makeCurrent({bool save = true, bool login = true}) {
    if (!resync()) {
      Arceus.talker.error(
          "Failed to resync star '$hash'. Cannot make it the current star.");
      return false;
    }
    try {
      constellation.starmap.currentStar = this;
      if (login) constellation.loggedInUser = user;
      if (save) constellation.save();
      Arceus.talker.info("Star '$hash' is now the current star.");
      return true;
    } catch (e) {
      Arceus.talker.error(
          "Failed to resync star '$hash'. Cannot make it the current star.");
      return false;
    }
  }

  /// # [Plasma] getPlasma(String pathOfFileInStar)
  /// ## Returns a new Plasma for a file at path relative to the star.
  Plasma getPlasma(String pathOfFileInStar) {
    final plasma = Plasma.fromStar(this, pathOfFileInStar);
    Arceus.talker.info("Got plasma '$pathOfFileInStar' in star '$hash'.");
    return plasma;
  }

  /// # [Star] getMostRecentStar()
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
      if (child.createdAt.isAfter(mostRecentStar.createdAt)) {
        mostRecentStar = child;
      }
    }
    return mostRecentStar.getMostRecentStar();
  }

  /// # List<[Star]> getDescendants()
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

  /// # List<[Star]> getAncestors()
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

  /// # String toString()
  /// ## Returns the hash of the star.
  @override
  String toString() => hash;

  /// # String getDisplayName()
  /// ## Returns the name of the star for displaying.
  /// This is used when printing the star to the terminal.
  /// The name will end with a ✨ if it's the current star.
  /// It will also show a user badge, and the first two tags attached to the star.
  String getDisplayName() {
    String fileName = file.getDisplayName();
    final displayName =
        "${!isRoot && isSingleChild ? "↪ " : ""}$fileName${isCurrent ? "✨" : ""}";
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
    return file.addTag(tag);
  }

  bool removeTag(String tag) {
    return file.removeTag(tag);
  }

  bool hasTag(String tag) {
    return file.hasTag(tag);
  }

  void clearTags() {
    file.clearTags();
  }

  /// # bool exactlyMatches(Star star)
  /// ## Returns true if the given star is exactly the same as this star.
  /// Returns false otherwise.
  /// This is NOT the same as == operator, as that only checks the hash, and not the star file.
  bool exactlyMatches(Star star) {
    if (star.hash == hash) {
      return file.getChecksum() == star.file.getChecksum();
    }
    return false;
  }
}

import 'package:archive/archive_io.dart';
import 'dart:convert';
import 'constellation.dart';
import 'users.dart';
import 'dart:io';

/// # `class` Star
/// ## Represents a star in the constellation.
/// Stars can be thought as an analog to Git commits.
/// They are saved as a `.star` file in the constellation's directory.
/// A `.star` file literally is just a ZIP file, so you can open them in 7Zip or WinRAR.
class Star {
  Constellation constellation;
  String? name; // The name of the star.
  String? hash; // The hash of the star.
  DateTime? createdAt; // The time the star was created.
  String? parentHash; // The hash of the parent star.
  String? _userHash; // The hash of the user who this star belongs to.
  User? get user => constellation.userIndex?.getUser(_userHash!);
  Star? get parent {
    if (parentHash == null) return null;
    return Star(constellation, hash: parentHash);
  }

  set parent(Star? value) {
    parentHash = value?.hash;
  }

  // List<String> get _children =>
  //     constellation.get; // The hashes of the children stars.

  Archive get archive => getArchive();

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
      load();
    } else {
      throw Exception("Star must have either a name and a user, or a hash.");
    }
  }

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

  String createChild(String name) {
    if (!constellation.checkForDifferences(hash)) {
      throw Exception(
          "Cannot create a child star when there are no differences. Please make changes and try again.");
    }
    Star star = Star(constellation, name: name);
    constellation.starmap?.addRelationship(this, star);
    constellation.starmap?.currentStar = star;
    constellation.save();
    return star.hash!;
  }

  /// # `Star` getParentStar()
  /// ## Returns the parent star.
  Star? getParentStar() {
    if (parentHash == null) return null;
    return Star(constellation, hash: parentHash);
  }

  /// # `void` load()
  /// ## Loads the star from disk.
  void load() {
    ArchiveFile? file = archive.findFile("star");
    _fromStarFileData(utf8.decode(file!.content));
  }

  void extract() {
    extractFileToDisk(constellation.getStarPath(hash!), constellation.path);
  }

  Archive getArchive() {
    final inputStream = InputFileStream(constellation.getStarPath(hash!));
    final archive = ZipDecoder().decodeBuffer(inputStream);
    return archive;
  }

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
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ansix/ansix.dart';
import 'package:archive/archive_io.dart';
import 'package:cli_spin/cli_spin.dart';

import 'uuid.dart';
import 'extensions.dart';

class Galaxy {}

/// # `class` Constellation
/// ## Represents a constellation.
/// Is similar to how a normal Git repository works, with an initial commit acting as the root star.
/// However, the plan is for Arceus to be able to do more with stars in the future,
/// so just using Git as a backbone would limit the scope of this project.
class Constellation {
  String? name; // The name of the constellation.
  String path; // The path to the folder this constellation is in.
  Directory get directory => Directory(
      path); // Fetches a directory object from the path this constellation is in.
  String? rootHash; // The hash of the root star.
  Star? get root =>
      Star(this, hash: rootHash!); // Fetches the root star as a Star object.
  set root(Star? value) => rootHash =
      value?.hash; // Sets the root star hash with the given Star object.
  String? currentStarHash; // The hash of the current star.
  Star? get currentStar => Star(this,
      hash: currentStarHash!); // Fetches the current star as a Star object.
  set currentStar(Star? value) => currentStarHash =
      value?.hash; // Sets the current star hash with the given Star object.

  bool doesStarExist(String hash) => File(getStarPath(hash)).existsSync();

  String get constellationPath =>
      "$path/.constellation"; // The path to the folder the constellation stores its data in.
  Directory get constellationDirectory => Directory(
      constellationPath); // Fetches a directory object from the path the constellation stores its data in.

  Constellation(this.path, {this.name}) {
    path = path.fixPath();
    if (constellationDirectory.existsSync()) {
      load();
      if (currentStarHash == null) {
        currentStarHash = rootHash;
        save();
      }
      return;
    } else if (name != null) {
      _createConstellationDirectory();
      _createRootStar();
      return;
    }
    throw Exception(
        "Constellation not found: $constellationPath. If the constellation does not exist, you must provide a name.");
  }

  /// # `void` _createConstellationDirectory()
  /// ## Creates the directory the constellation stores its data in.
  void _createConstellationDirectory() {
    constellationDirectory.createSync();
    if (Platform.isWindows) {
      Process.runSync('attrib', ['+h', constellationPath]);
    }
  }

  void _createRootStar() {
    root = Star(this, name: "Initial Star");
    currentStar = root;
    save();
  }

  String generateUniqueStarHash() {
    while (true) {
      String hash = generateUUID();
      if (!(doesStarExist(hash))) {
        return hash;
      }
    }
  }

  /// # `String` getStarPath(`String` hash)
  /// ## Returns a path for a star with the given hash.
  String getStarPath(String hash) => "$constellationPath/$hash.star";

  // ============================================================================
  // These methods are for saving and loading the constellation.

  /// # `void` save()
  /// ## Saves the constellation to disk.
  /// This includes the root star and the current star hashes.
  void save() {
    File file = File("$constellationPath/starmap");
    file.createSync();
    file.writeAsStringSync(jsonEncode(toJson()));
  }

  void load() {
    File file = File("$constellationPath/starmap");
    if (file.existsSync()) {
      fromJson(jsonDecode(file.readAsStringSync()));
    }
  }

  void fromJson(Map<String, dynamic> json) {
    name = json["name"];
    rootHash = json["rootHash"];
    currentStarHash = json["currentStarHash"];
  }

  Map<String, dynamic> toJson() =>
      {"name": name, "rootHash": rootHash, "currentStarHash": currentStarHash};
  // ============================================================================

  /// # `DiffFile` getDiffFile(`String` filename)
  /// ## Returns a `DiffFile` object with the contents of the given file currently.
  /// The filename must be relative to the constellation's path.
  /// So, if for example the constellation is at `C:/Example/` and the file is at `C:/Example/example.txt`,
  /// the filename should be `example.txt`.
  DiffFile getDiffFile(String filename) {
    return DiffFile(file: File("$path/$filename"));
  }

  /// # `void` showMap()
  /// ## Shows the map of the constellation.
  /// This is a tree view of the constellation's stars and their children.
  void showMap() {
    AnsiX.printTreeView((root?.getReadableTree()),
        theme: AnsiTreeViewTheme(
          showListItemIndex: false,
          headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
          valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
          anchorTheme: AnsiTreeAnchorTheme(
              style: AnsiBorderStyle.rounded, color: AnsiColor.blueViolet),
        ));
  }

  operator >>(Object to) {
    if (to is String && doesStarExist(to)) {
      currentStar = Star(this, hash: to);
    } else if (to is Star) {
      currentStar = to;
    }
  }

  bool checkForDifferences(String? hash) {
    hash ??= currentStarHash;
    Star star = Star(this, hash: hash);
    return star.checkForDifferences();
  }
}

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
  Star? get parent {
    if (parentHash == null) return null;
    return Star(constellation, hash: parentHash);
  }

  set parent(Star? value) {
    parentHash = value?.hash;
  }

  List<String> _children = []; // The hashes of the children stars.

  Archive get archive => getArchive();

  Star(this.constellation, {this.name, this.hash}) {
    if (name != null && hash == null) {
      _create();
      save();
    } else if (name == null && hash != null) {
      load();
    }
  }

  void _create() {
    createdAt = DateTime.now();
    hash = constellation.generateUniqueStarHash();
  }

  String createChild(String name) {
    Star star = Star(constellation, name: name)..parent = this;
    _children.add(star.hash!);
    return star.hash!;
  }

  Star? getChildStar({String? hash, int? index}) {
    if (hash == null && index != null) {
      try {
        return Star(constellation, hash: _children[index]);
      } catch (e) {
        return null;
      }
    } else if (hash != null) {
      if (!(_children.contains(hash))) {
        throw Exception(
            "Star not found: $hash. Either the star does not exist or it is not a child of this star.");
      }
      return Star(constellation, hash: hash);
    }
    throw Exception("Must provide either a hash or an index for a child star.");
  }

  void save() {
    final encoder = _createArchive(hash!);
    String data = _generateStarFileData();
    ArchiveFile file = ArchiveFile("star", data.length, data);
    encoder.addArchiveFile(file);
    encoder.closeSync();
  }

  void load() {
    ArchiveFile? file = archive.findFile("star");
    _fromStarFileData(utf8.decode(file!.content));
  }

  void extract() {
    extractFileToDisk(constellation.getStarPath(hash!), constellation.path);
  }

  DiffFile buildFile(String filename) {
    if (parent != null) {
      return DiffFile(file: archive.findFile(filename)) +
          parent!.buildFile(filename);
    } else {
      return DiffFile(file: archive.findFile(filename));
    }
  }

  Archive getArchive() {
    if (!(File(constellation.getStarPath(hash!)).existsSync())) {
      save();
    }
    final inputStream = InputFileStream(constellation.getStarPath(hash!));
    final archive = ZipDecoder().decodeBuffer(inputStream);
    return archive;
  }

  ZipFileEncoder _createArchive(String hash) {
    var archive = ZipFileEncoder();
    archive.create(constellation.getStarPath(hash));
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
    final file = File(constellation.getStarPath(hash));
    file.statSync();
    return archive;
  }

  void _fromStarFileData(String data) {
    fromJson(jsonDecode(data));
  }

  Map<String, dynamic> getReadableTree() {
    Map<String, dynamic> list = {};
    String displayName = "$name - $hash";
    list[displayName] = {};
    for (int x = 1; x < ((_children.length)); x++) {
      list[displayName]
          .addAll(getChildStar(hash: _children[x])!.getReadableTree());
    }
    if (_children.isNotEmpty) {
      list.addAll(getChildStar(index: 0)!.getReadableTree());
    }
    return list;
  }

  /// # `String` _generateStarFileData()
  /// ## Generates the data for the `star` file inside the `.star`.
  /// Inside a `.star` file, there is a single file just called `star` with no extension.
  /// This file contains the star's data in JSON format.
  String _generateStarFileData() {
    return jsonEncode(toJson());
  }

  void fromJson(Map<String, dynamic> json) {
    name = json["name"];
    createdAt = DateTime.tryParse(json["createdAt"]);
    try {
      _children = json["children"];
    } catch (e) {
      _children = [];
    }
  }

  /// # `bool` checkForDifferences()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool checkForDifferences() {
    final spinner = CliSpin(text: "Checking for new files...").start();
    for (FileSystemEntity entity
        in constellation.directory.listSync(recursive: true)) {
      if (entity is File &&
          (!entity.path.endsWith(".star") &&
              !entity.path.endsWith("starmap"))) {
        if (archive.findFile(entity.path
                .replaceFirst("${constellation.path}\\", "")
                .fixPath()) ==
            null) {
          spinner.fail("New file found: ${entity.path}");
          return true;
        }
      }
    }
    spinner.success("There are no new files.");
    for (ArchiveFile file in archive.files) {
      if (file.isFile && file.name != "star") {
        DiffFile diff = DiffFile(file: file);
        DiffFile other = constellation.getDiffFile(file.name);
        if (diff != other) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() =>
      {"name": name, "createdAt": createdAt.toString(), "children": []};
}

/// # `class` DiffFile
/// ## A simple object that contains a file's path and its contents.
/// It allows for easy diffing and masking.
/// The class uses operators for quickly checking for differences, but also creating masks.
///
/// Checking if Different:
/// ```dart
/// DiffFile diff = DiffFile(file: File("example.txt"));
/// DiffFile other = DiffFile(file: File("example.txt"));
/// if (diff != other) {
///   print("Different");
/// }
/// ```
/// Creating a Mask:
/// ```dart
/// DiffFile diff = DiffFile(file: File("example.txt"));
/// DiffFile other = DiffFile(file: File("example.txt"));
/// DiffFile mask = diff - other;
/// ```
/// Applying a Mask:
/// ```dart
///  DiffFile diff = DiffFile(file: File("example.txt"));
///  DiffFile other = DiffFile(file: File("example.txt"));
///  DiffFile built = diff + other;
/// ```
class DiffFile {
  String? path;
  Uint8List? data;
  DiffFile({Object? file, this.path, this.data}) {
    if (file is File) {
      path = file.path;
      data = file.readAsBytesSync();
    } else if (file is ArchiveFile) {
      path = file.name;
      data = file.content as Uint8List;
    }
  }

  DiffFile _createDiffMask(DiffFile other) {
    final spinner =
        CliSpin(text: "Creating diff mask for ${path!.split("/").last}...")
            .start();
    Uint8List diff = Uint8List(0);
    int x = 0;
    while (x < data!.length) {
      if (data![x] != other.data![x]) {
        diff.add(data![x]);
      } else {
        diff.add(0);
      }
      x += 1;
    }
    if (x < other.data!.length) {
      diff.addAll(other.data!.sublist(x));
    }
    spinner.success("Created diff mask for ${path!.split("/").last}.");
    return DiffFile(path: path, data: diff);
  }

  DiffFile _buildDiffFile(DiffFile other) {
    Uint8List diff = Uint8List(0);
    int x = 0;
    while (x < data!.length) {
      if (other.data![x] == 0) {
        diff.add(data![x]);
      } else {
        diff.add(other.data![x]);
      }
      x += 1;
    }
    if (x < other.data!.length) {
      diff.addAll(other.data!.sublist(x));
    }
    return DiffFile(path: path, data: diff);
  }

  @override
  int get hashCode => path.hashCode ^ data.hashCode;

  bool _checkForDifferences(DiffFile other) {
    for (int x = 0; x < data!.length; x++) {
      if (data![x] != other.data![x]) {
        return true;
      }
    }
    return false;
  }

  @override
  operator ==(Object other) {
    if (other is! DiffFile) {
      return false;
    }
    final spinner = CliSpin(
      text: "Checking ${path?.split("/").last}...",
    ).start();
    if (data?.length != other.data?.length && !_checkForDifferences(other)) {
      spinner.fail("${path?.split("/").last} is different.");
      return false;
    }
    spinner.success("${path?.split("/").last} has not changed.");
    return true;
  }

  operator +(DiffFile other) {
    return _buildDiffFile(other);
  }

  operator -(DiffFile other) {
    return _createDiffMask(other);
  }
}

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

  operator [](Object to) {
    if (to is String && doesStarExist(to)) {
      currentStar = Star(this, hash: to);
    } else if (to is Star) {
      currentStar = to;
    }
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
    return Dossier(star).checkForDifferences();
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

  /// # `Star` getParentStar()
  /// ## Returns the parent star.
  Star? getParentStar() {
    if (parentHash == null) return null;
    return Star(constellation, hash: parentHash);
  }

  /// # `void` save()
  /// ## Saves the star to disk.
  void save() {
    final encoder = _createArchive(hash!);
    String data = _generateStarFileData();
    ArchiveFile file = ArchiveFile("star", data.length, data);
    encoder.addArchiveFile(file);
    encoder.closeSync();
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

  /// # `Map<String, dynamic>` getReadableTree()
  /// ## Returns a readable tree of the star.
  /// This is useful for debugging.
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

  /// # `void` fromJson(`Map<String, dynamic>` json)
  /// ## Converts the JSON data into a `Star` object.
  void fromJson(Map<String, dynamic> json) {
    name = json["name"];
    createdAt = DateTime.tryParse(json["createdAt"]);
    try {
      _children = json["children"];
    } catch (e) {
      _children = [];
    }
  }

  /// # `Map<String, dynamic>` toJson()
  /// ## Converts the `Star` object into a JSON object.
  Map<String, dynamic> toJson() =>
      {"name": name, "createdAt": createdAt.toString(), "children": _children};
}

/// # `class` `Dossier`
/// ## A wrapper for the internal and external file systems.
/// Acts as a wrapper for the internal file system (i.e. Inside a `.star` file) and the external file system (i.e. Inside the current directory).
class Dossier {
  Star star;

  String addSymbol = "A".bold().green();
  String removeSymbol = "D".bold().red();
  String moveSymbol = "→".bold().aqua();
  String modifiedSymbol = "M".bold().yellow();
  Dossier(this.star);

  /// # `bool` checkForDifferences()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool checkForDifferences() {
    bool check =
        false; // The main check. If any of the preceding checks fail, this will be true, which means that there is a difference.

    // There are four checks that need to be done:
    // 1. Check for new files.
    // 2. Check for removed files.
    // 3. Check for moved files.
    // 4. Check for changed files.

    // Check for new files.
    var spinner = CliSpin(text: "Checking for new files...").start();
    List<String> newFiles = [];
    for (FileSystemEntity entity
        in star.constellation.directory.listSync(recursive: true)) {
      if (entity is File &&
          (!entity.path.endsWith(".star") &&
              !entity.path.endsWith("starmap"))) {
        if (star.archive
                .findFile(entity.path.makeRelPath(star.constellation.path)) ==
            null) {
          newFiles.add(entity.path.makeRelPath(star.constellation.path));
        }
      }
    }
    spinner.stop();

    // Check for removed files.
    spinner = CliSpin(text: "Checking for removed files...").start();
    List<String> removedFiles = [];
    for (ArchiveFile file in star.archive.files) {
      if (file.isFile && file.name != "star") {
        if (!File("${star.constellation.path}/${file.name}").existsSync()) {
          removedFiles.add(file.name);
        }
      }
    }
    spinner.stop();

    // Check for moved files. Done after new and removed files, as they can be used here to make a cross reference.
    spinner = CliSpin(text: "Checking for moved files...").start();
    Map<String, String> movedFiles = {};
    for (String file in removedFiles) {
      if (newFiles.any((e) => e.getFilename() == file.getFilename())) {
        ExternalFile externalFile = ExternalFile(
            "${star.constellation.path}/${newFiles.firstWhere((e) => e.getFilename() == file.getFilename())}");
        InternalFile internalFile = InternalFile(star, file);
        if (externalFile == internalFile) {
          movedFiles[file] =
              newFiles.firstWhere((e) => e.getFilename() == file.getFilename());
        }
      }
    }
    if (movedFiles.isNotEmpty) {
      spinner.stop();
      for (String file in movedFiles.keys) {
        print("$file $moveSymbol ${movedFiles[file]}");
      }
      check = true;
    } else {
      spinner.success("There are no moved files.");
    }

    if (newFiles.isNotEmpty) {
      for (String file in newFiles) {
        if (movedFiles.containsValue(file)) {
          continue;
        }
        print("$addSymbol $file");
        check = true;
      }
    } else {
      spinner.success("There are no new files.");
    }

    if (removedFiles.isNotEmpty) {
      for (String file in removedFiles) {
        if (movedFiles.containsKey(file)) {
          continue;
        }
        print("$removeSymbol $file");
        check = true;
      }
    } else {
      spinner.success("There are no removed files.");
    }

    // Check for changed files.
    for (ArchiveFile file in star.archive.files) {
      if (file.isFile &&
          file.name != "star" &&
          !removedFiles.contains(file.name)) {
        DossierFile dossierFile = DossierFile(star, "star://${file.name}");
        spinner =
            CliSpin(text: "Checking for changes to: ${file.name}...").start();
        if (dossierFile.hasChanged()) {
          print("$modifiedSymbol ${file.name}");
          check = true;
        }
        spinner.stop();
      }
    }
    return check;
  }
}

/// # `class` `DossierFile`
/// ## A wrapper for the internal and external for a single file in both the internal and external file systems.
class DossierFile {
  Star star;
  String path;
  String? filename;
  InternalFile? internalFile;
  ExternalFile? externalFile;

  DossierFile(this.star, this.path) {
    if (path.startsWith(star.constellation.path)) {
      filename = path.makeRelPath(star.constellation.path);
    } else if (path.startsWith("star://")) {
      filename = path.replaceFirst("star://", "");
    } else {
      throw Exception("Invalid path: $path");
    }
    open();
  }

  /// # `void` open()
  /// ## Opens the internal and external version of the file.
  void open() {
    externalFile = ExternalFile("${star.constellation.path}/${filename!}");
    internalFile = InternalFile(star, filename!);
  }

  /// # `bool` hasChanged()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool hasChanged() {
    // ignore: unrelated_type_equality_checks
    return internalFile != externalFile;
  }
}

/// # `mixin` `CheckForDifferencesInData`
/// ## A mixin to check for differences in data, for use in the `BaseFile` class.
mixin CheckForDifferencesInData {
  bool _check(Uint8List data1, Uint8List data2) {
    if (data1.length != data2.length) {
      return true;
    }
    for (int x = 0; x < data1.length; x++) {
      if (data1[x] != data2[x]) {
        return true;
      }
    }
    return false;
  }
}

/// # `class` `BaseFile`
/// ## A base class for internal and external files.
/// Represents an internal file (i.e. inside a `.star` file) or an external file (i.e. inside the current directory).
sealed class BaseFile with CheckForDifferencesInData {
  String path;
  Uint8List get data => Uint8List(0);
  set data(Uint8List newData) {
    throw UnimplementedError(
        "Not implemented. Please implement in a subclass.");
  }

  BaseFile(this.path);

  /// # `operator` `==`
  /// ## Checks to see if the file is different from another file.
  @override
  operator ==(Object other) {
    if (other is BaseFile) {
      return !_check(data, other.data);
    }
    return false;
  }

  @override
  int get hashCode => data.hashCode;
}

/// # `class` `InternalFile` extends `BaseFile`
/// ## Represents an internal file (i.e. inside a `.star` file).
class InternalFile extends BaseFile {
  Star star;

  @override
  Uint8List get data => build();

  @override
  set data(Uint8List newData) {
    if (star.archive.findFile(path) != null) {
      throw Exception("You cannot set data for a existing file inside a star.");
    }
    star.archive.addFile(ArchiveFile(path, newData.length, newData));
  }

  InternalFile(this.star, super.path) {
    if (star.getArchive().findFile(path) == null) {
      throw Exception(
          "File not found: $path. Please check the path and star and try again.");
    }
  }

  Uint8List build() {
    Star? currentStar = star.getParentStar();
    Uint8List data = star.getArchive().findFile(path)?.content as Uint8List;
    while (currentStar != null) {
      Uint8List content =
          currentStar.getArchive().findFile(path)?.content as Uint8List;
      for (int x = 0; x < data.length; x++) {
        if (data[x] == 0) {
          data[x] = content[x];
        }
      }
      currentStar = currentStar.getParentStar();
    }
    return data;
  }
}

/// # `class` ExternalFile extends `BaseFile`
/// ## Represents an external file (i.e. inside the current directory).
class ExternalFile extends BaseFile {
  ExternalFile(super.path);

  @override
  Uint8List get data => File(path).readAsBytesSync();

  @override
  set data(Uint8List newData) {
    File(path).writeAsBytesSync(newData);
  }
}

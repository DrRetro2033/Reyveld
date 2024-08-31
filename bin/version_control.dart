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

  late Starmap starmap;

  Directory get directory => Directory(
      path); // Fetches a directory object from the path this constellation is in.

  bool doesStarExist(String hash) => File(getStarPath(hash)).existsSync();

  String get constellationPath =>
      "$path/.constellation"; // The path to the folder the constellation stores its data in.
  Directory get constellationDirectory => Directory(
      constellationPath); // Fetches a directory object from the path the constellation stores its data in.

  Constellation(this.path, {this.name}) {
    path = path.fixPath();
    if (constellationDirectory.existsSync()) {
      load();
      if (starmap.currentStarHash == null) {
        starmap.currentStarHash = starmap.rootHash;
        save();
      }
      return;
    } else if (name != null) {
      _createConstellationDirectory();
      starmap = Starmap(this);
      _createRootStar();
      save();
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
    starmap.root = Star(this, name: "Initial Star");
    starmap.currentStar = starmap.root;
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
    starmap = Starmap(this, map: json["map"]);
  }

  Map<String, dynamic> toJson() => {"name": name, "map": starmap.toJson()};
  // ============================================================================

  String? branch(String name) {
    return starmap.currentStar?.createChild(name);
  }

  // List<String> listChildren(String hash) {}

  bool checkForDifferences(String? hash) {
    hash ??= starmap.currentStarHash;
    Star star = Star(this, hash: hash);
    return Dossier(star).checkForDifferences();
  }
}

/// # `class` Starmap
/// ## Represents the relationship between stars.
/// This now contains the root star and the current star.
/// It also contains the children and parents of each star, in two separate maps, for performance and ease reading and writing.
class Starmap {
  Constellation constellation;

  // Maps for storing children and parents.
  Map<String, List<dynamic>> childMap = {}; // Format: {parent: [children]}
  Map<String, dynamic> parentMap = {}; // Format: {child: parent}

  Starmap(this.constellation, {Map<dynamic, dynamic>? map}) {
    if (map == null) {
      childMap = {};
      parentMap = {};
    } else {
      fromJson(map);
    }
  }

  String? rootHash; // The hash of the root star.
  Star? get root => Star(constellation,
      hash: rootHash!); // Fetches the root star as a Star object.
  set root(Star? value) => rootHash =
      value?.hash; // Sets the root star hash with the given Star object.
  String? currentStarHash; // The hash of the current star.
  Star? get currentStar => Star(constellation,
      hash: currentStarHash!); // Fetches the current star as a Star object.
  set currentStar(Star? value) => currentStarHash =
      value?.hash; // Sets the current star hash with the given Star object.

  /// # `void` initEntry(`String` hash)
  /// ## Initializes the entry for the given hash.
  /// Called by `Star` when a new star is created.
  void initEntry(String hash) {
    if (childMap[hash] != null) {
      return;
    }
    childMap[hash] = [];
  }

  /// # `void` jumpTo(`String?` hash)
  /// ## Changes the current star to the star with the given hash.
  void jumpTo(String? hash) {
    if (constellation.doesStarExist(hash ?? rootHash!)) {
      currentStar = Star(constellation, hash: hash ?? rootHash!);
    }
  }

  /// # `operator` `[]` jumpTo(`Star` star)
  /// ## Changes the current star to the given star.
  /// You can pass a hash or a star object.
  operator [](Object to) {
    if (to is String && constellation.doesStarExist(to)) {
      jumpTo(to);
    } else if (to is Star) {
      currentStar = to;
    }
  }

  Map<dynamic, dynamic> toJson() {
    return {
      "root": rootHash,
      "current": currentStarHash,
      "children": childMap,
      "parents": parentMap
    };
  }

  void fromJson(Map<dynamic, dynamic> json) {
    rootHash = json["root"];
    currentStarHash = json["current"];
    for (String hash in json["children"].keys) {
      childMap[hash] = json["children"][hash];
    }
    for (String hash in json["parents"].keys) {
      parentMap[hash] = json["parents"][hash];
    }
  }

  /// # `List<Star>` getChildren(`Star` parent)
  /// ## Returns a list of all children of the given parent.
  /// The list will be empty if the parent has no children.
  List<Star> getChildren(Star parent) {
    List<Star> children = [];
    for (String hash in getChildrenHashes(parent.hash!)) {
      children.add(Star(constellation, hash: hash));
    }
    return children;
  }

  /// # `List<String>` getChildrenHashes(`String` parent)
  /// ## Returns a list of all children hashes of the given parent.
  /// The list will be empty if the parent has no children.
  List getChildrenHashes(String parent) {
    return childMap[parent] ?? <String>[];
  }

  /// # `void` addRelationship(`Star` parent, `Star` child)
  /// ## Adds the given child to the given parent.
  void addRelationship(Star parent, Star child) {
    if (parentMap[child.hash] != null) {
      throw Exception("Star already has a parent.");
    }

    if (childMap[parent.hash] == null) {
      childMap[parent.hash!] = [];
    }
    childMap[parent.hash!]?.add(child.hash!);
    parentMap[child.hash!] = parent.hash!;
    constellation.save();
  }

  /// # `Map<String, dynamic>` getReadableTree(`String` curHash)
  /// ## Returns a tree view of the constellation.
  Map<String, dynamic> getReadableTree(String curHash) {
    Map<String, dynamic> list = {};
    String displayName = "Star $curHash";
    if (currentStarHash == curHash) {
      displayName += "✨";
    }
    list[displayName] = {};
    for (int x = 1; x < ((getChildrenHashes(curHash).length)); x++) {
      list[displayName].addAll(getReadableTree(getChildrenHashes(curHash)[x]));
    }
    if (getChildrenHashes(curHash).isNotEmpty) {
      list.addAll(getReadableTree(getChildrenHashes(curHash)[0]));
    }
    return list;
  }

  /// # `void` showMap()
  /// ## Shows the map of the constellation.
  /// This is a tree view of the constellation's stars and their children.
  void showMap() {
    AnsiX.printTreeView(getReadableTree(rootHash!),
        theme: AnsiTreeViewTheme(
          showListItemIndex: false,
          headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
          valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
          anchorTheme: AnsiTreeAnchorTheme(
              style: AnsiBorderStyle.rounded, color: AnsiColor.blueViolet),
        ));
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

  // List<String> get _children =>
  //     constellation.get; // The hashes of the children stars.

  Archive get archive => getArchive();

  Star(this.constellation, {this.name, this.hash}) {
    constellation.starmap.initEntry(hash ?? "");
    if (name != null && hash == null) {
      _create();
    } else if (name == null && hash != null) {
      load();
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
    constellation.starmap.addRelationship(this, star);
    constellation.starmap.currentStar = star;
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
  }

  /// # `Map<String, dynamic>` toJson()
  /// ## Converts the `Star` object into a JSON object.
  Map<String, dynamic> toJson() => {
        "name": name,
        "createdAt": createdAt.toString(),
      };
}

/// # `class` `Dossier`
/// ## A wrapper for the internal and external file systems.
/// Acts as a wrapper for the internal file system (i.e. Inside a `.star` file) and the external file system (i.e. Inside the current directory).
class Dossier {
  Star star; // The star used for the internal file system.

  // The following are used for the CLI:
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
    List<String> newFiles = listAddedFiles();
    spinner.stop();

    // Check for removed files.
    spinner = CliSpin(text: "Checking for removed files...").start();
    List<String> removedFiles = listRemovedFiles();
    spinner.stop();

    // Check for moved files. Done after new and removed files, as they can be used here to make a cross reference.
    spinner = CliSpin(text: "Checking for moved files...").start();
    Map<String, String> movedFiles = listMovedFiles(newFiles, removedFiles);
    if (movedFiles.isNotEmpty) {
      check = true;
      spinner.stop();
      for (String file in movedFiles.keys) {
        print("$file $moveSymbol ${movedFiles[file]}");
      }
    } else {
      spinner.success("There are no moved files.");
    }

    if (newFiles.isNotEmpty) {
      check = true;
      for (String file in newFiles) {
        if (movedFiles.containsValue(file)) {
          continue;
        }
        print("$addSymbol $file");
      }
    } else {
      spinner.success("There are no new files.");
    }

    if (removedFiles.isNotEmpty) {
      check = true;
      for (String file in removedFiles) {
        if (movedFiles.containsKey(file)) {
          continue;
        }
        print("$removeSymbol $file");
      }
    } else {
      spinner.success("There are no removed files.");
    }

    // Check for changed files.
    spinner = CliSpin(text: "Checking for changed files...").start();
    List<String> changedFiles = listChangedFiles(removedFiles);
    if (changedFiles.isNotEmpty) {
      spinner.stop();
      check = true;
      for (String file in changedFiles) {
        print("$modifiedSymbol $file");
      }
    } else {
      spinner.success("There are no changed files.");
    }
    return check;
  }

  List<String> listAddedFiles() {
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
    return newFiles;
  }

  List<String> listRemovedFiles() {
    List<String> removedFiles = [];
    for (ArchiveFile file in star.archive.files) {
      if (file.isFile && file.name != "star") {
        if (!File("${star.constellation.path}/${file.name}").existsSync()) {
          removedFiles.add(file.name);
        }
      }
    }
    return removedFiles;
  }

  Map<String, String> listMovedFiles(
      List<String> newFiles, List<String> removedFiles) {
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
    return movedFiles;
  }

  List<String> listChangedFiles(List<String> removedFiles) {
    List<String> changedFiles = [];
    for (ArchiveFile file in star.archive.files) {
      if (file.isFile &&
          file.name != "star" &&
          !removedFiles.contains(file.name)) {
        DossierFile dossierFile = DossierFile(star, "star://${file.name}");
        if (dossierFile.hasChanged()) {
          changedFiles.add(file.name);
        }
      }
    }
    return changedFiles;
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

import 'dart:convert';
import 'dart:io';

import 'package:ansix/ansix.dart';
import 'package:archive/archive_io.dart';

import 'uuid.dart';
import 'extensions.dart';

class Galaxy {}

class Constellation {
  String? name;
  String path;
  Directory get directory => Directory(path);
  String? rootHash;
  Star? get root => Star(this, hash: rootHash!);
  set root(Star? value) => rootHash = value?.hash;
  String? currentStarHash;
  Star? get currentStar => Star(this, hash: currentStarHash!);
  set currentStar(Star? value) => currentStarHash = value?.hash;
  String get constellationPath => "$path/.constellation";
  Directory get constellationDirectory => Directory(constellationPath);

  Constellation(this.path, {this.name}) {
    path = path.fixPath();
    if (constellationDirectory.existsSync()) {
      load();
      return;
    } else if (name != null) {
      _createConstellationDirectory();
      _createRootStar();
      return;
    }
    throw Exception(
        "Constellation not found: $constellationPath. If the constellation does not exist, you must provide a name.");
  }

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
      if (!(File(getStarPath(hash)).existsSync())) {
        return hash;
      }
    }
  }

  String getStarPath(String hash) => "$constellationPath/$hash.star";

  ZipFileEncoder createArchive(String hash) {
    var archive = ZipFileEncoder();
    if (File(getStarPath(hash)).existsSync()) {
      archive.open(getStarPath(hash));
      return archive;
    }
    archive.create(getStarPath(hash));
    for (FileSystemEntity entity in directory.listSync()) {
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
    return archive;
  }

  Archive getArchive(String hash) {
    final inputStream = InputFileStream(getStarPath(hash));
    final archive = ZipDecoder().decodeBuffer(inputStream);
    return archive;
  }

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
}

class Star {
  Constellation constellation;
  String? name;
  String? hash;
  DateTime? createdAt;
  List<String> children = [];
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
    Star star = Star(constellation, name: name);
    children.add(star.hash!);
    return star.hash!;
  }

  Star? getChildStar({String? hash, int? index}) {
    if (hash == null && index != null) {
      try {
        return Star(constellation, hash: children[index]);
      } catch (e) {
        return null;
      }
    } else if (hash != null) {
      if (!(children.contains(hash))) {
        throw Exception(
            "Star not found: $hash. Either the star does not exist or it is not a child of this star.");
      }
      return Star(constellation, hash: hash);
    }
    throw Exception("Must provide either a hash or an index for a child star.");
  }

  void save() {
    final archive = constellation.createArchive(hash!);
    String data = _generateStarFileData();
    ArchiveFile file = ArchiveFile("star", data.length, data);
    archive.addArchiveFile(file);
    archive.closeSync();
  }

  void load() {
    final archive = constellation.getArchive(hash!);
    ArchiveFile? file = archive.findFile("star");
    _fromStarFileData(utf8.decode(file!.content));
  }

  void extract() {
    extractFileToDisk(constellation.getStarPath(hash!), constellation.path);
  }

  void _fromStarFileData(String data) {
    fromJson(jsonDecode(data));
  }

  Map<String, dynamic> getReadableTree() {
    Map<String, dynamic> list = {};
    String displayName = "$name - $hash";
    list[displayName] = {};
    for (int x = 1; x < ((children.length)); x++) {
      list[displayName]
          .addAll(getChildStar(hash: children[x])!.getReadableTree());
    }
    if (children.isNotEmpty) {
      list.addAll(getChildStar(index: 0)!.getReadableTree());
    }
    return list;
  }

  String _generateStarFileData() {
    return jsonEncode(toJson());
  }

  void fromJson(Map<String, dynamic> json) {
    name = json["name"];
    hash = json["hash"];
    createdAt = DateTime.tryParse(json["createdAt"]);
    try {
      children = json["children"];
    } catch (e) {
      children = [];
    }
  }

  Map<String, dynamic> toJson() =>
      {"name": name, "hash": hash, "createdAt": createdAt, "children": []};
}

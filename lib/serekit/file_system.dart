import 'dart:convert';
import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/serekit.dart';

class SArchive extends SObject {
  static Set<String> markedForDeletion = {};

  SArchive(super._kit, super._node);

  String get hash => get("hash")!;

  set hash(String? hash) => set("hash", hash);

  DateTime get archivedOn => DateTime.parse(get("date")!);

  /// Marks the archive for deletion.
  /// Adds the archive's hash to the [markedForDeletion] set.
  /// Will not trigger save, must be done manually.
  void markForDeletion() => markedForDeletion.add(hash);

  /// Adds a [SFile] to the archive.
  /// Does not trigger save, must be done manually.
  void addSFile(SFile file) => addChild(file);

  /// Adds a file to the archive.
  /// [filepath] should be relative to the archive. For instance: "C://path/to/folder/example.txt" will translate to "example.txt".
  Future<void> addFile(String filepath, List<int> data) async {
    final file =
        await SFileFactory().create(kit, {"path": filepath, "data": data});
    addSFile(file);
  }

  SFile? getFile(String path) {
    return getChild<SFile>(filter: (e) => e.path == path);
  }
}

class SArchiveFactory extends SFactory<SArchive> {
  @override
  String get tag => "archive";

  @override
  SArchive load(SKit kit, XmlNode node) => SArchive(kit, node);

  @override
  get requiredAttributes => {"hash": (dynamic value) => value is String};

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        final hash = attributes["hash"];
        if (hash == null) throw ArgumentError.notNull("hash");
        builder.element("archive", nest: () {
          builder.attribute("hash", hash);
        });
      };
}

/// A file in an [SArchive].
/// Contains the path of the file, and its data in the form of compressed base64.
class SFile extends SObject {
  SFile(super._kit, super._node);

  /// Returns the path of the file.
  String get path => get("path")!;

  /// Returns the data of the file as a list of bytes.
  List<int> get bytes {
    final encoded = innerText!;
    return gzip.decode(base64Decode(encoded));
  }

  /// Returns the data of the file as a string.
  String get text => utf8.decode(bytes);
}

/// Factory for creating [SFile]s.
class SFileFactory extends SFactory<SFile> {
  @override
  String get tag => "file";

  @override
  get requiredAttributes => {
        "path": (value) => value is String,
        "data": (value) => value is List<int>
      };

  @override
  SFile load(SKit kit, XmlNode node) => SFile(kit, node);

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        final path = attributes["path"] as String;
        builder.element("file", nest: () async {
          builder.attribute("path", path.fixPath());
          builder.text(base64Encode(gzip.encode(attributes["data"])));
        });
      };
}

/// A reference to an [SArchive].
/// Contains the hash of the archive.
class SRArchive extends SObject {
  SRArchive(super.kit, super.node);

  String get hash => get("hash")!;

  set hash(String? hash) => set("hash", hash);

  Future<SArchive?> get archive => kit.getArchive(hash);
}

class SRArchiveFactory extends SFactory<SRArchive> {
  @override
  String get tag => "rarchive";

  @override
  SRArchive load(SKit kit, XmlNode node) => SRArchive(kit, node);

  @override
  get requiredAttributes =>
      {"hash": (value) => value is String && value.isNotEmpty};

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("rarchive", nest: () {
          builder.attribute("hash", attributes["hash"]);
        });
      };
}

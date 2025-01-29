import 'dart:convert';
import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/serekit.dart';

class SArchive extends SObject {
  static Set<String> markedForDeletion = {};

  SArchive(super._kit, super._node);

  String? get hash => get("hash");

  /// Marks the commit for deletion.
  /// Adds the commit's hash to the [markedForDeletion] set.
  /// Will not trigger save, must be done manually.
  void markForDeletion() => markedForDeletion.add(hash!);

  /// Adds a file to the archive.
  /// Does not trigger save, must be done manually.
  void addFile(SFile file) => addChild(file);

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

class SFile extends SObject {
  SFile(super._kit, super._node);

  String get path => get("path")!;

  List<int> get data {
    final encoded = innerText!;
    return gzip.decode(base64Decode(encoded));
  }
}

class SFileFactory extends SFactory<SFile> {
  @override
  String get tag => "file";

  @override
  get requiredAttributes => {
        "file": (dynamic value) => value is File,
      };

  @override
  SFile load(SKit kit, XmlNode node) => SFile(kit, node);

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) async {
        final file = attributes["file"] as File;
        List<int> bytes = await file.readAsBytes();
        builder.element("file", nest: () async {
          builder.attribute("path", file.path.fixPath());
          builder.text(base64Encode(gzip.encode(bytes)));
        });
      };
}

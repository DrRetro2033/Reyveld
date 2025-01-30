import 'dart:io';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/version_control/star.dart';

class Constellation extends SObject {
  Constellation(super._kit, super._node);

  String get name => get("name") ?? "Constellation";

  String get path => get("path")!.fixPath();

  DateTime get currentDate => DateTime.parse(get("cur")!);

  set currentDate(DateTime value) => set("cur", value.toIso8601String());

  Uri get uri => Uri.parse(path);

  set path(String value) => set("path", value.fixPath());

  /// Creates the root [Star] of the constellation.
  /// This is used when creating a new constellation.
  Future<void> createRootStar() async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception("Path does not exist.");
    }
    final archive = await kit.createArchive();
    for (final file in dir.listSync(recursive: true)) {
      /// Get all of the files in the current directory recursively,
      /// and add them to the new archive, making them relative to the archive.
      if (file is File) {
        await archive.addFile(
            file.path.relativeTo(path), await file.readAsBytes());
      }
    }
    final rootStar = await StarFactory()
        .create(kit, {"name": "Initial Star", "archiveHash": archive.hash});
    addChild(rootStar);
    currentDate = rootStar.createdOn;
  }
}

class ConstFactory extends SFactory<Constellation> {
  @override
  get requiredAttributes => {
        "name": (e) => e is String && e.isNotEmpty,
        "path": (e) async =>
            e is String && e.isNotEmpty && await Directory(e).exists()
      };

  @override
  Constellation load(SKit kit, XmlNode node) => Constellation(kit, node);

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("const", nest: () {
          builder.attribute("name", attributes["name"]);
          builder.attribute("path", attributes["path"]);
        });
      };

  @override
  String get tag => "const";
}

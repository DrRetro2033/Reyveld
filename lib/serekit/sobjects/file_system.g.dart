part of 'file_system.dart';

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

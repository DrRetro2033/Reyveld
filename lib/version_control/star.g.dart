part of 'star.dart';

/// Factory for [Star] objects.
class StarFactory extends SFactory<Star> {
  @override
  String get tag => "star";

  @override
  Star load(SKit kit, XmlNode node) => Star(kit, node);

  @override
  get requiredAttributes => {
        "name": (value) => value is String && value.isNotEmpty,
        "hash": (value) => value is String && value.isNotEmpty,
        "archiveHash": (value) => value is String && value.isNotEmpty,
      };

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("star", nest: () {
          builder.attribute("name", attributes["name"]);
          builder.attribute("hash", attributes["hash"]);
          builder.attribute("date", DateTime.now().toIso8601String());
          SRArchiveFactory()
              .creator(builder, {"hash": attributes["archiveHash"]});
        });
      };
}

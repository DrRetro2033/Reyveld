part of 'header.dart';

class SHeaderFactory extends SFactory<SHeader> {
  @override
  String get tag => "sere";

  @override
  get requiredAttributes => {"type": (e) => e is SKitType};

  @override
  SHeader load(SKit kit, XmlNode node) {
    return SHeader(kit, node);
  }

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("sere", nest: () {
          builder.attribute("createdOn", DateTime.now().toIso8601String());
          builder.attribute("lastModified", DateTime.now().toIso8601String());
          builder.attribute("version", Updater.currentVersion.toString());
          builder.attribute(
              "type", (attributes["type"] as SKitType).index.toString());
        });
      };
}

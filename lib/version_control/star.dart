import 'package:arceus/serekit.dart';

class Star extends SObject {
  Star(super._node);

  String get name => get("name") ?? "Initial Star";

  set name(String value) => set("name", value);

  static Star fromXml(XmlNode node) => Star(node);

  static XmlBuilder create() {
    final builder = XmlBuilder();
    builder.element("star", nest: () {
      builder.attribute("name", "Initial Star");
    });
    return builder;
  }
}

class StarFactory extends SFactory<Star> {
  @override
  String get tag => "star";

  @override
  Star load(XmlNode node) => Star(node);

  @override
  void create(XmlBuilder builder, [Map<String, String> overrides = const {}]) {
    builder.element("star", nest: () {
      if (overrides.containsKey("name")) {
        builder.attribute("name", overrides["name"]);
      } else {
        builder.attribute("name", "Initial Star");
      }
    });
  }
}

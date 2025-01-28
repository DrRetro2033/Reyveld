import 'package:arceus/serekit.dart';

class Constellation extends SObject {
  Constellation(super._node);

  String get name => get("name") ?? "Constellation";
}

class ConstFactory extends SFactory<Constellation> {
  @override
  Constellation load(XmlNode node) => Constellation(node);

  @override
  void create(XmlBuilder builder, [Map<String, String> overrides = const {}]) {
    builder.element("const", nest: () {
      if (overrides.containsKey("name")) {
        builder.attribute("name", overrides["name"]);
      } else {
        builder.attribute("name", "Constellation");
      }
    });
  }

  @override
  String get tag => "const";
}

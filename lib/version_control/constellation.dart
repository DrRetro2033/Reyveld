import 'package:arceus/serekit/serekit.dart';

class Constellation extends SObject {
  Constellation(super._kit, super._node);

  String get name => get("name") ?? "Constellation";
}

class ConstFactory extends SFactory<Constellation> {
  @override
  Constellation load(SKit kit, XmlNode node) => Constellation(kit, node);

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("const", nest: () {
          builder.attribute("name", attributes["name"] ?? "Constellation");
        });
      };

  @override
  String get tag => "const";
}

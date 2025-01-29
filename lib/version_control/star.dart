import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/serekit/file_system.dart';

class Star extends SObject {
  Star(super._kit, super._node);

  String get name => get("name") ?? "Initial Star";

  set name(String value) => set("name", value);

  Future<SArchive> get archive async => await kit.getArchive(get("comit")!);

  static Star fromXml(SKit kit, XmlNode node) => Star(kit, node);

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
  Star load(SKit kit, XmlNode node) => Star(kit, node);

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("star", nest: () {
          builder.attribute("name", attributes["name"] ?? "Initial Star");
        });
      };
}

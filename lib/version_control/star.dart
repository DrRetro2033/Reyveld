import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/serekit/file_system.dart';

class Star extends SObject {
  Star(super._kit, super._node);

  String get name => get("name") ?? "Initial Star";

  set name(String value) => set("name", value);

  Future<SArchive> get archive async => await kit.getArchive(get("comit")!);

  DateTime get createdOn => DateTime.parse(get("date")!);
}

class StarFactory extends SFactory<Star> {
  @override
  String get tag => "star";

  @override
  Star load(SKit kit, XmlNode node) => Star(kit, node);

  @override
  get requiredAttributes => {
        "name": (value) => value is String && value.isNotEmpty,
        "archiveHash": (value) => value is String && value.isNotEmpty,
      };

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("star", nest: () {
          builder.attribute("name", attributes["name"] ?? "Initial Star");
          builder.attribute("comit", attributes["archiveHash"]);
          builder.attribute("date", DateTime.now().toIso8601String());
        });
      };
}

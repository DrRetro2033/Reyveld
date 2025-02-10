part of 'constellation.dart';

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

extension ConstellationExtension on SKit {
  Future<Constellation?> getConstellation() async {
    final header = await getKitHeader();
    return header.getChild<Constellation>();
  }
}

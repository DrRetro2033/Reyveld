part of 'description.dart';

class DescriptionFactory extends SFactory<Description> {
  @override
  Description load(SKit kit, XmlNode node) => Description(kit, node);

  @override
  String get tag => "descr";

  @override
  get requiredAttributes =>
      {"text": (value) => value is String && value.isNotEmpty};

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element(tag, nest: () {
          builder.text(attributes["text"]);
        });
      };
}

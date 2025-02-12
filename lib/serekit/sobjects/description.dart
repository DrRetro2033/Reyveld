import 'package:arceus/serekit/sobject.dart';

part 'description.g.dart';

/// This [SObject] is used for descriptions that could be a paragraph.

@SGen("descr")
class Description extends SObject {
  Description(super.kit, super._node);

  String get body => innerText ?? "";

  static create(XmlBuilder builder, Map<String, dynamic> attributes) {
    builder.text(attributes["text"]);
  }
}

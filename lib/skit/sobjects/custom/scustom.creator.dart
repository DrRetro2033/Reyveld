part of 'scustom.dart';

class SCustomCreator extends SCreator<SCustom> {
  /// The custom type to assign for this [SCustom].
  final String type;

  /// The initial attributes of the [SCustom].
  final Map<String, dynamic>? attributes;

  SCustomCreator(this.type, this.attributes);

  @override
  build(builder) {
    builder.attribute("type", type);
    if (attributes != null) {
      for (var entry in attributes!.entries) {
        if (entry.key == "type") {
          continue; // Avoid overwriting the type attribute with another attribute.
        }
        builder.attribute(entry.key, entry.value.toString());
      }
    }
  }
}

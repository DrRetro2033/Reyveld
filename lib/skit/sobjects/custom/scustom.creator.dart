part of 'scustom.dart';

class SCustomCreator extends SCreator<SCustom> {
  final String type;
  final Map<String, dynamic>? attributes;

  SCustomCreator(this.type, this.attributes);

  @override
  get creator => (builder) {
        builder.attribute("type", encodeText(type));
        if (attributes != null) {
          for (var entry in attributes!.entries) {
            if (entry.key == "type") {
              continue; // Avoid overwriting the type attribute
            }
            builder.attribute(entry.key, encodeText(entry.value.toString()));
          }
        }
      };
}

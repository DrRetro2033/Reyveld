part of 'description.dart';

class DescriptionCreator extends SCreator<SDescription> {
  final String text;

  DescriptionCreator(this.text);

  @override
  get creator => (builder) {
        builder.text(base64Encode(text.codeUnits));
      };
}

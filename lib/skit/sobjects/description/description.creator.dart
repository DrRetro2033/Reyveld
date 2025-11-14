part of 'description.dart';

class SDescriptionCreator extends SCreator<SDescription> {
  final String text;

  SDescriptionCreator(this.text);

  @override
  build(builder) {
    builder.cdata(text);
  }
}

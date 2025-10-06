part of 'description.dart';

class SDescriptionCreator extends SCreator<SDescription> {
  final String text;

  SDescriptionCreator(this.text);

  @override
  get creator => (builder) {
        builder.cdata(text);
      };
}

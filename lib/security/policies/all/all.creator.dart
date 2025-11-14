part of 'all.dart';

class SPolicyAllCreator extends SCreator<SPolicyAll> {
  final String? reasoning;

  SPolicyAllCreator({this.reasoning});

  @override
  build(builder) {
    if (reasoning != null) {
      builder.sobject(SDescriptionCreator(reasoning!).create());
    }
  }
}

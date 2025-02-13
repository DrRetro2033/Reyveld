import 'package:arceus/serekit/sobject.dart';

part 'description.g.dart';

/// This [SObject] is used for descriptions that could be a paragraph.

@SGen("descr")
class Description extends SObject {
  Description(super.kit, super._node);

  String get body => innerText ?? "";
}

class DescriptionCreator extends SCreator<Description> {
  final String text;

  DescriptionCreator(this.text);

  @override
  get creator => (builder) {
        builder.text(text);
      };
}

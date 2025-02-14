import 'dart:convert';

import 'package:arceus/serekit/sobject.dart';

part 'description.g.dart';

/// This [SObject] is used for descriptions that could be a whole paragraph.

@SGen("descr")
class Description extends SObject {
  Description(super.kit, super._node);

  String get body => String.fromCharCodes(base64Decode(get("text") ?? ""));
}

class DescriptionCreator extends SCreator<Description> {
  final String text;

  DescriptionCreator(this.text);

  @override
  get creator => (builder) {
        builder.text(base64Encode(text.codeUnits));
      };
}

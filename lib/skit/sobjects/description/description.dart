import 'dart:convert';

import 'package:arceus/skit/sobject.dart';

part 'description.g.dart';
part 'description.creator.dart';

/// This [SObject] is used for descriptions of things in the kit file.

@SGen("descr")
class SDescription extends SObject {
  SDescription(super._node);
  String get body => String.fromCharCodes(base64Decode(get("text") ?? ""));
}

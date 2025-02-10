import 'dart:async';

import 'package:arceus/serekit/sobject.dart';
import 'package:arceus/serekit/sobjects/description.dart';
import 'package:arceus/serekit/sobjects/file_system.dart';
import 'package:version/version.dart';

part 'addon.g.dart';

class Addon extends SObject {
  Addon(super.kit, super.node);

  String get name => get("name")!;
  String get description => getChild<Description>()!.body;
  Version get version => Version.parse(get("version")!);

  /// Returns the script archive from the addon.
  FutureOr<SArchive?> get archive => getChild<SRArchive>()!.getRef();
}

enum FeatureSets {
  pattern,
  intergration,
}

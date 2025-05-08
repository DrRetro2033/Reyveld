import 'package:arceus/skit/sobject.dart';

class SAuthor extends SObject {
  String get name => get("name")!;
  String? get email => get("email");
  String? get github => get("github");
  String? get twitter => get("twitter");
  String? get bluesky => get("bluesky");
  String? get threads => get("threads");
  String? get discord => get("discord");
  String? get patreon => get("patreon");
  String? get website => get("website");

  SAuthor(super.kit, super.node);
}

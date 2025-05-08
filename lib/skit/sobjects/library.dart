import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';

/// This class represents a Arceus library.
/// A library contains a name, an archive reference, a description, and a list of authors.
class SLibrary extends SObject {
  SLibrary(super.key, super.node);

  String get name => get("name")!;
  set name(String value) => set("name", value);

  Future<SArchive> get archive =>
      getChild<SRArchive>()!.getRef().then((value) => value!);

  String get description => getChild<SDescription>()!.body;

  List<SAuthor?> get authors => getChildren<SAuthor>();
}

import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';

part 'library.g.dart';
part 'library.creator.dart';
part 'library.interface.dart';

/// This class represents an Arceus library.
/// A library contains a name, an archive reference, a description, and a list of authors.
///
/// A library is a collection of SKits that contain Lua code that can be used to reuse code between projects easily.
/// For example, you can create a library that contains code to read and write Pokemon from a file, or
/// read and write to an image file, or more.
class SLibrary extends SObject {
  SLibrary(super.node);

  String get name => get("name")!;
  set name(String value) => set("name", value);

  Future<SArchive> get archive =>
      getChild<SRArchive>()!.getRef().then((value) => value!);

  String get description => getChild<SDescription>()!.body;

  List<SAuthor?> get authors => getChildren<SAuthor>();

  Future<void> package(String path) async {
    final archive = await SArchiveCreator.archiveFolder(path,
        filter: (e) => e.path.endsWith(".lua"));
    await kit.addRoot(archive);
    addChild(await archive.newIndent<SRArchive>());
    return;
  }
}

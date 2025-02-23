part of 'file_system.dart';

class SArchiveCreator extends SRootCreator<SArchive> {
  SArchiveCreator();

  /// Creates a new archive from a folder.
  /// Adds all of the files in the folder to the archive, making them relative to the archive.
  /// Will add the new archive to the kit, and returns it.
  static Future<SArchive> archiveFolder(SKit kit, String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception("Path does not exist.");
    }
    final archive = await SArchiveCreator().create(kit);
    for (final file in dir.listSync(recursive: true)) {
      /// Get all of the files in the current directory recursively,
      /// and add them to the new archive, making them relative to the archive.
      if (file is File) {
        await archive.addFile(file.path.relativeTo(path), file.openRead());
      }
    }
    kit.addRoot(archive);
    return archive;
  }

  @override
  get creator => (builder) {};
}

class SFileCreator extends SCreator<SFile> {
  final String path;
  final Stream<List<int>> stream;
  late String data;

  SFileCreator(this.path, this.stream);

  @override
  get beforeCreate => (kit) async {
        final bytes = stream.transform(gzip.encoder).transform(base64.encoder);
        data = await bytes.reduce((a, b) => a + b);
      };

  @override
  get creator => (builder) {
        builder.attribute("path", path.fixPath());
        builder.text(data);
      };
}

class SRArchiveCreator extends SCreator<SRArchive> {
  final String archiveHash;

  SRArchiveCreator(this.archiveHash);
  @override
  get creator => (builder) {
        builder.attribute("hash", archiveHash);
      };
}

part of 'file_system.dart';

/// Creates [SArchive]s.
class SArchiveCreator extends SCreator<SArchive> {
  SArchiveCreator();

  /// Creates a new archive from a folder.
  /// Adds all of the files in the folder to the archive, making them relative to the archive.
  /// Will add the new archive to the kit, and returns it.
  static Future<SArchive> archiveFolder(String path, {SArchive? ref}) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception("Path does not exist.");
    }
    final archive = await SArchiveCreator().create();
    for (final file in dir.listSync(recursive: true)) {
      /// Get all of the files in the current directory recursively,
      /// and add them to the new archive, making them relative to the archive.
      if (file is File) {
        final filePath = file.path.relativeTo(path);
        if (ref != null && ref.hasFile(filePath)) {
          if (!await ref
              .getFile(filePath)!
              .streamDiff(file.openRead())
              .any((e) => e.any((e) => e != 0))) {
            archive.addSFile(await SRFileCreator(ref.hash, filePath).create());
            continue;
          }
        }
        await archive.addFile(file.path.relativeTo(path), file.openRead());
      }
    }
    return archive;
  }

  @override
  get creator => (builder) {};
}

/// Creates [SFile]s.
class SFileCreator extends SCreator<SFile> {
  final String path;
  final Stream<List<int>> stream;
  late String data;

  SFileCreator(this.path, this.stream);

  @override
  get beforeCreate => () async {
        final bytes = stream.transform(gzip.encoder).transform(base64.encoder);
        data = await bytes.reduce((a, b) => a + b);
      };

  @override
  get creator => (builder) {
        builder.attribute("path", path.fixPath());
        builder.text(data);
      };
}

/// Creates [SRFile]s.
class SRFileCreator extends SCreator<SRFile> {
  final String archiveHash;
  final String filePath;
  SRFileCreator(this.archiveHash, this.filePath);

  @override
  get creator => (builder) {
        builder.attribute("archive", archiveHash);
        builder.attribute("path", filePath.fixPath());
      };
}

/// Creates [SRArchive]s.
typedef SRArchiveCreator = SIndentCreator<SRArchive>;

part of 'file_system.dart';

/// Creates [SArchive]s.
class SArchiveCreator extends SCreator<SArchive> {
  SArchiveCreator();

  /// Creates a new archive from a folder.
  /// Adds all of the files in the folder to the archive, making them relative to the archive.
  /// Will add the new archive to the kit, and returns it.
  static Future<SArchive> archiveFolder(String path,
      {SArchive? ref, Globs? includeList}) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception("Path does not exist.");
    }
    final archive = await SArchiveCreator().create();

    await for (final file in _archiveFolderStream(
      dir.list(recursive: true).whereType<File>().where((e) =>
          includeList?.included(e.path.resolvePath().relativeTo(path)) ?? true),
      path,
      ref: ref,
    )) {
      archive.addChild(file);
    }

    return archive;
  }

  static Stream<SFile> _archiveFolderStream(Stream<File> stream, String path,
      {SArchive? ref, bool Function(String)? filter}) async* {
    await for (final e in stream) {
      final filePath = e.path.relativeTo(path);
      if (filter != null && !filter(filePath)) continue;
      yield await Isolate.run<SFile>(() async {
        if (ref != null && ref.hasFile(filePath)) {
          if (ref.getFile(filePath)!.checksum == await e.checksum) {
            return await ref.getFile(filePath)!.getRef();
          }
        }
        return await SFileCreator(filePath, await e.checksum, e.openRead())
            .create();
      });
    }
  }

  @override
  get creator => (builder) {};
}

/// Creates [SFile]s.
class SFileCreator extends SCreator<SFile> {
  final String path;
  final Stream<List<int>> stream;
  final bool isExternal;
  late String data;
  final String checksum;

  SFileCreator(this.path, this.checksum, this.stream,
      {this.isExternal = false});

  static Future<SFile> open(String path) async {
    final file = SFileCreator(
        path, await File(path).checksum, File(path).openRead(),
        isExternal: true);
    return await file.create();
  }

  @override
  get beforeCreate => () async {
        final bytes = stream.transform(gzip.encoder).transform(base64.encoder);
        data = await bytes.reduce((a, b) => a + b);
      };

  @override
  get creator => (builder) {
        builder.attribute("path", path);
        builder.attribute("checksum", checksum);
        builder.attribute("extern", isExternal ? "1" : "0");
        builder.text(data);
      };
}

/// Creates [SRFile]s.
class SRFileCreator extends SCreator<SRFile> {
  final String archiveHash;
  final String filePath;
  final String checksum;
  SRFileCreator(this.archiveHash, this.filePath, this.checksum);

  @override
  get creator => (builder) {
        builder.attribute("archive", archiveHash);
        builder.attribute("path", filePath);
        builder.attribute("checksum", checksum);
      };
}

/// Creates [SRArchive]s.
typedef SRArchiveCreator = SIndentCreator<SRArchive>;

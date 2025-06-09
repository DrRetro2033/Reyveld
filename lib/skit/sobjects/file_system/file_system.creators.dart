part of 'file_system.dart';

/// Creates [SArchive]s.
class SArchiveCreator extends SCreator<SArchive> {
  SArchiveCreator();

  /// Creates a new archive from a folder.
  /// Adds all of the files in the folder to the archive, making them relative to the archive.
  /// Will add the new archive to the kit, and returns it.
  static Future<SArchive> archiveFolder(String path,
      {SArchive? ref, bool Function(File)? filter}) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception("Path does not exist.");
    }
    final archive = await SArchiveCreator().create();

    await for (final file in _archiveFolderStream(
        dir.list(recursive: true).whereType(), path,
        ref: ref, filter: filter)) {
      archive.addChild(file!);
    }

    return archive;
  }

  static Stream<SFile?> _archiveFolderStream(Stream<File> stream, String path,
      {SArchive? ref, bool Function(File)? filter}) async* {
    await for (final e in stream) {
      if (filter != null && !filter(e)) yield null;
      yield await Isolate.run<SFile?>(() async {
        final filePath = e.path.relativeTo(path);
        if (ref != null && ref.hasFile(filePath)) {
          if (ref.getFile(filePath)!.checkSum ==
              sha256sum(await e
                  .openRead()
                  .transform(gzip.encoder)
                  .transform(base64.encoder)
                  .reduce((a, b) => a + b))) {
            return await SRFileCreator(
                    ref.hash, filePath, ref.getFile(filePath)!.checkSum)
                .create();
          }
        }
        return await SFileCreator(filePath, e.openRead()).create();
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
  late String checkSum;

  SFileCreator(this.path, this.stream, {this.isExternal = false});

  static Future<SFile> open(String path) async {
    final file = SFileCreator(path, File(path).openRead(), isExternal: true);
    return await file.create();
  }

  @override
  get beforeCreate => () async {
        final bytes = stream.transform(gzip.encoder).transform(base64.encoder);
        data = await bytes.reduce((a, b) => a + b);
        checkSum = sha256sum(data);
      };

  @override
  get creator => (builder) {
        builder.attribute("path", path.fixPath());
        builder.attribute("checksum", checkSum);
        builder.attribute("extern", isExternal ? "1" : "0");
        builder.text(data);
      };
}

/// Creates [SRFile]s.
class SRFileCreator extends SCreator<SRFile> {
  final String archiveHash;
  final String filePath;
  final String checkSum;
  SRFileCreator(this.archiveHash, this.filePath, this.checkSum);

  @override
  get creator => (builder) {
        builder.attribute("archive", archiveHash);
        builder.attribute("path", filePath.fixPath());
        builder.attribute("checksum", checkSum);
      };
}

/// Creates [SRArchive]s.
typedef SRArchiveCreator = SIndentCreator<SRArchive>;

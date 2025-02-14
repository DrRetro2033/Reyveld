part of 'file_system.dart';

class SArchiveCreator extends SCreator<SArchive> {
  final String hash;

  SArchiveCreator(this.hash);

  @override
  get creator => (builder) {
        builder.attribute("hash", hash);
      };
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
        builder.cdata(data);
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

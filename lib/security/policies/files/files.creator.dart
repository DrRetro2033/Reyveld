part of 'files.dart';

class SPolicyFilesCreator extends SCreator<SPolicyFiles> {
  final bool read;
  final bool write;

  /// Also known as "create".
  final bool init;
  final bool delete;

  final Whitelist whitelist;
  SPolicyFilesCreator(
      {required this.read,
      required this.write,
      required this.init,
      required this.delete,
      required this.whitelist});
  @override
  get creator => (builder) {
        builder.boolAttri("read", read);
        builder.boolAttri("write", write);
        builder.boolAttri("create", init);
        builder.boolAttri("delete", delete);
        builder.sobject(whitelist);
      };
}

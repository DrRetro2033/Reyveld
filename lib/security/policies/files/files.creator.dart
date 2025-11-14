part of 'files.dart';

class SPolicyFilesCreator extends SCreator<SPolicyFiles> {
  final String? reasoning;
  final bool readExternally;
  final bool writeExternally;
  final bool createExternally;
  final bool deleteExternally;

  final bool readInternally;
  final bool writeInternally;
  final bool createInternally;
  final bool deleteInternally;

  final Whitelist whitelist;
  SPolicyFilesCreator(
      {this.reasoning,
      this.readExternally = false,
      this.writeExternally = false,
      this.createExternally = false,
      this.deleteExternally = false,
      this.readInternally = false,
      this.writeInternally = false,
      this.createInternally = false,
      this.deleteInternally = false,
      required this.whitelist});
  @override
  build(builder) {
    builder.boolAttri("rexter", readExternally);
    builder.boolAttri("wexter", writeExternally);
    builder.boolAttri("cexter", createExternally);
    builder.boolAttri("dexter", deleteExternally);

    builder.boolAttri("rinter", readInternally);
    builder.boolAttri("winter", writeInternally);
    builder.boolAttri("cinter", createInternally);
    builder.boolAttri("dinter", deleteInternally);
    builder.sobject(whitelist);
    if (reasoning != null) {
      builder.sobject(SDescriptionCreator(reasoning!).create());
    }
  }
}

part of 'skit.dart';

class SPolicySKitCreator extends SCreator<SPolicySKit> {
  final String? reasoning;
  final bool read;
  final bool write;

  /// Also known as "create".
  final bool init;
  final bool delete;
  SPolicySKitCreator(
      {this.reasoning,
      required this.read,
      required this.write,
      required this.init,
      required this.delete});

  @override
  build(builder) {
    builder.boolAttri("read", read);
    builder.boolAttri("write", write);
    builder.boolAttri("create", init);
    builder.boolAttri("delete", delete);
    if (reasoning != null) {
      builder.sobject(SDescriptionCreator(reasoning!).create());
    }
  }
}

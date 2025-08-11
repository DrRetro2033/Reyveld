part of 'skit.dart';

class SPolicySKitCreator extends SCreator<SPolicySKit> {
  final bool read;
  final bool write;

  /// Also known as "create".
  final bool init;
  final bool delete;
  SPolicySKitCreator(
      {required this.read,
      required this.write,
      required this.init,
      required this.delete});
  @override
  get creator => (builder) {
        builder.boolAttri("read", read);
        builder.boolAttri("write", write);
        builder.boolAttri("create", init);
        builder.boolAttri("delete", delete);
      };
}

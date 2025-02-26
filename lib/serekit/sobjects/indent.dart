import 'package:arceus/serekit/sobject.dart';

part 'indent.g.dart';

@SGen("indent")
class SIndent extends SObject {
  String get hash => get("hash")!;
  String get rootType => get("type")!;

  @override
  operator ==(Object other) =>
      other is SIndent && other.rootType == rootType && other.hash == hash;

  @override
  int get hashCode => hash.hashCode;
  SIndent(super.kit, super.node);
}

class SIndentCreator extends SCreator<SIndent> {
  final SFactory type;
  final String hash;

  SIndentCreator(this.type, this.hash);

  @override
  get creator => (builder) {
        builder.attribute('type', type.tag);
        builder.attribute('hash', hash);
      };
}

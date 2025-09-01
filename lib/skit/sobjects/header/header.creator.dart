part of 'header.dart';

class SHeaderCreator extends SCreator<SHeader> {
  final SKitType type;

  SHeaderCreator({this.type = SKitType.unspecified});

  @override
  get creator => (builder) {
        builder.attribute("createdOn", DateTime.now().toIso8601String());
        builder.attribute("lastModified", DateTime.now().toIso8601String());
        builder.attribute("version", Reyveld.version.toString());
        builder.attribute("type", type.index.toString());
      };
}

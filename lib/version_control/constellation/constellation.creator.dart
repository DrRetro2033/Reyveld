part of 'constellation.dart';

/// The creator for [Constellation]s.
class ConstellationCreator extends SCreator<Constellation> {
  final String name;
  final String path;

  ConstellationCreator(this.name, this.path);

  @override
  build(builder) {
    builder.attribute("name", name);
    builder.attribute("path", path);
  }

  static Future<Constellation> start(String name, String path) async {
    final creator = ConstellationCreator(name, path);
    final constellation = creator.create();
    await constellation.createRootStar();
    return constellation;
  }
}

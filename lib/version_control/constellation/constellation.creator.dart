part of 'constellation.dart';

class ConstellationCreator extends SCreator<Constellation> {
  final String name;
  final String path;

  ConstellationCreator(this.name, this.path);

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("path", path);
      };
}

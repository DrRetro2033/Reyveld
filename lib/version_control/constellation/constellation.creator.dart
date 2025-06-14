part of 'constellation.dart';

class ConstellationCreator extends SCreator<Constellation> {
  final String name;
  final String path;

  ConstellationCreator(this.name, this.path);

  @override
  get creator => (builder) {
        builder.attribute("name", name.formatForXML());
        builder.attribute("path", path.fixPath());
      };
}

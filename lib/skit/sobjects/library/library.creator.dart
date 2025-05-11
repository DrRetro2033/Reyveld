part of 'library.dart';

class SLibraryCreator extends SCreator<SLibrary> {
  final String name;
  final String description;
  final List<SAuthor> authors;

  SLibraryCreator(this.name, {this.description = "", this.authors = const []});

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("description", description);
        for (final author in authors) {
          builder.xml(author.toXmlString());
        }
      };
}

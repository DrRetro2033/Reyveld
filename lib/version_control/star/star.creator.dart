part of 'star.dart';

class StarCreator extends SCreator<Star> {
  final String name;
  final String hash;
  final SRArchive archiveIndent;

  StarCreator(this.name, this.hash, this.archiveIndent);
  @override
  get creator => (builder) {
        builder.attribute("name", name.formatForXML());
        builder.attribute("hash", hash);
        builder.attribute("date", DateTime.now().toIso8601String());
        builder.xml(archiveIndent.toXmlString());
      };
}

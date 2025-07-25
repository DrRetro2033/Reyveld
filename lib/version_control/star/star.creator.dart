part of 'star.dart';

class StarCreator extends SCreator<Star> {
  final String name;
  final String hash;
  final String? branch;
  final SRArchive archiveIndent;

  StarCreator(this.name, this.hash, this.archiveIndent, {this.branch});
  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("hash", hash);
        if (branch != null) {
          builder.attribute("branch", branch!);
        }
        builder.attribute("date", DateTime.now().toIso8601String());
        builder.xml(archiveIndent.toXmlString());
      };
}

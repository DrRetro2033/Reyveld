part of 'star.dart';

class StarCreator extends SCreator<Star> {
  final String name;
  final String id;
  final String? branch;
  final SRArchive archiveIndent;

  StarCreator(this.name, this.id, this.archiveIndent, {this.branch});

  @override
  build(builder) {
    builder.attribute("name", name);
    builder.attribute("hash", id);
    if (branch != null) {
      builder.attribute("branch", branch!);
    }
    builder.attribute("date", DateTime.now().toIso8601String());
    builder.xml(archiveIndent.toXmlString());
  }
}

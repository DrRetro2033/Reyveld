import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/serekit/file_system.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/widget_system.dart';

class Star extends SObject {
  Star(super._kit, super._node);

  String get name => get("name") ?? "Initial Star";

  set name(String value) => set("name", value);

  String get hash => get("hash")!;

  set hash(String value) => set("hash", value);

  Future<SArchive?> get archive async => getChild<SRArchive>()!.archive;

  DateTime get createdOn => DateTime.parse(get("date")!);

  Constellation get constellation => getAncestor<Constellation>()!;

  bool get isRoot => constellation.getChild<Star>() == this;

  bool get isCurrent => constellation.currentHash == hash;

  bool get isSingleChild => getParent<Star>()?.getChildren<Star>().length == 1;

  /// Grows a new star from this star.
  /// Returns the new star.
  /// Does not trigger save.
  Future<Star> grow(String name) async {
    final factory = StarFactory();
    final archive = await kit.archiveFolder(constellation.path);
    final star = await factory.create(kit, {
      "name": name,
      "archiveHash": archive.hash,
      "hash": constellation.newStarHash()
    });
    addChild(star);
    constellation.currentHash = star.hash;
    return star;
  }

  /// Returns the formatted name of the star file for displaying.
  /// This is used when printing details about a star file to the terminal.
  String getDisplayName() {
    // int tagsToDisplay = 2;
    List<Badge> badges = [];
    // for (String tag in tags) {
    //   if (tagsToDisplay == 0) {
    //     break;
    //   }
    //   badges.add(Badge("🏷️$tag"));
    //   tagsToDisplay--;
    // }
    Badge dateBadge = Badge(
        '📅${createdOn.year}/${createdOn.month}/${createdOn.day}',
        badgeColor: "grey",
        textColor: "white");
    Badge timeBadge = Badge(
        '🕒${createdOn.hour % 12 == 0 ? 12 : createdOn.hour % 12}:${createdOn.minute.toString().padLeft(2, '0')} ${createdOn.hour >= 12 ? 'PM' : 'AM'}',
        badgeColor: "grey",
        textColor: "white");
    final displayName =
        "$name $dateBadge$timeBadge${badges.isNotEmpty ? badges.join(" ") : ""}";
    return "${!isRoot && isSingleChild ? "↪ " : ""}$displayName${isCurrent ? "✨" : ""}";
  }
}

class StarFactory extends SFactory<Star> {
  @override
  String get tag => "star";

  @override
  Star load(SKit kit, XmlNode node) => Star(kit, node);

  @override
  get requiredAttributes => {
        "name": (value) => value is String && value.isNotEmpty,
        "hash": (value) => value is String && value.isNotEmpty,
        "archiveHash": (value) => value is String && value.isNotEmpty,
      };

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("star", nest: () {
          builder.attribute("name", attributes["name"]);
          builder.attribute("hash", attributes["hash"]);
          builder.attribute("date", DateTime.now().toIso8601String());
          builder.element("rarchive", nest: () {
            builder.attribute("hash", attributes["archiveHash"]);
          });
        });
      };
}

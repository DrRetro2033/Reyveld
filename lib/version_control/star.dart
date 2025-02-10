import 'package:arceus/main.dart';
import 'package:arceus/serekit/sobject.dart';
import 'package:arceus/serekit/sobjects/file_system.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/widget_system.dart';

part 'star.g.dart';

/// This class represents a star in a constellation.
/// A star is a node in the constellation tree, and contains a reference to an archive.
/// TODO: Add multi-user support, either by making a unique constellation for each user, or by associating the star with a user.
class Star extends SObject {
  Star(super._kit, super._node);

  /// Returns the name of the star.
  String get name => get("name") ?? "Initial Star";

  /// Sets the name of the star.
  set name(String value) => set("name", value);

  /// Returns the hash of the star.
  String get hash => get("hash")!;

  /// Sets the hash of the star.
  set hash(String value) => set("hash", value);

  /// Returns the archive of the star.
  Future<SArchive?> get archive async => getChild<SRArchive>()!.getRef();

  /// Returns the date the star was created.
  DateTime get createdOn => DateTime.parse(get("date")!);

  /// Returns the constellation of the star.
  Constellation get constellation => getAncestors<Constellation>().first!;

  /// Returns true if the star is the root star.
  bool get isRoot => constellation.getChild<Star>() == this;

  /// Returns true if the star is the current star.
  bool get isCurrent => constellation.currentHash == hash;

  /// Returns true if the star is a single child.
  bool get isSingleChild => getParent<Star>()?.getChildren<Star>().length == 1;

  /// Grows a new star from this star.
  /// Returns the new star.
  Future<Star> grow(String name) async {
    final factory = StarFactory();
    final archive = await kit.archiveFolder(constellation.path);
    final star = await factory.create(kit, {
      "name": name,
      "archiveHash": archive.hash,
      "hash": constellation.newStarHash()
    });
    addChild(star);
    star.makeCurrent();
    return star;
  }

  /// Makes this star the current star.
  Future<void> makeCurrent() async {
    constellation.currentHash = hash;
    await archive.then((value) => value!.extract(constellation.path));
  }

  /// Returns the formatted name of the star file for displaying.
  /// This is used when printing details about a star file to the terminal.
  /// TODO: Add support for tags.
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
    Badge dateBadge = Badge('📅${settings!.formatDate(createdOn)}',
        badgeColor: "grey", textColor: "white");
    Badge timeBadge = Badge('🕒${settings!.formatTime(createdOn)}',
        badgeColor: "grey", textColor: "white");
    final displayName =
        "$name $dateBadge$timeBadge${badges.isNotEmpty ? badges.join(" ") : ""}";
    return "${!isRoot && isSingleChild ? "↪ " : ""}$displayName${isCurrent ? "✨" : ""}";
  }

  Future<bool> checkForChanges() async {
    return archive
        .then<bool>((value) => value!.checkForChanges(constellation.path));
  }
}

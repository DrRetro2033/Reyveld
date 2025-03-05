import 'dart:async';

import 'package:arceus/serekit/sobject.dart';
import 'package:arceus/serekit/sobjects/description.dart';
import 'package:arceus/serekit/sobjects/file_system.dart';
import 'package:version/version.dart';

part 'addon.g.dart';

@SGen("addon")
class Addon extends SObject {
  @override
  String get displayName => "Addon $name";

  Addon(super.kit, super.node);

  String get name => get("name")!;
  String get description => getChild<SDescription>()!.body;
  Version get version => Version.parse(get("version")!);

  /// Returns the script archive from the addon.
  FutureOr<SArchive?> get archive => getChild<SRArchive>()!.getRef();
}

class AddonCreator extends SCreator<Addon> {
  final String name;
  final String description;
  final String archiveHash;
  final Set<AddonDeveloper> developers;
  late SRArchive archive;
  late SDescription _description;

  AddonCreator(
      {required this.name,
      required this.description,
      required this.archiveHash,
      required this.developers});

  @override
  get beforeCreate => (kit) async {
        archive = await SRArchiveCreator(archiveHash).create(kit);
        _description = await DescriptionCreator(description).create(kit);
      };

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.xml(_description.toXmlString());
        builder.xml(archive.toXmlString());
        for (final dev in developers) {
          builder.xml(dev.toXmlString());
        }
      };
}

enum FeatureSets {
  pattern,
  intergration,
}

class AddonDeveloper extends SObject {
  @override
  String get displayName => "Developer";

  AddonDeveloper(super.kit, super.node);

  String get name => get("name")!;
  String get email => get("email")!;
  String? get website => get("website");
}

class AddonDeveloperCreator extends SCreator<AddonDeveloper> {
  final String name;
  final String email;
  final String? website;

  AddonDeveloperCreator(this.name, this.email, [this.website]);

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("email", email);
        if (website != null) builder.attribute("website", website!);
      };
}

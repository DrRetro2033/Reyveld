part of 'addon.dart';

class AddonFactory extends SFactory<Addon> {
  @override
  Addon load(SKit kit, XmlNode node) => Addon(kit, node);

  @override
  String get tag => "addon";

  @override
  get requiredAttributes => {
        "name": (value) => value is String && value.isNotEmpty,
        "description": (value) => value is String && value.isNotEmpty,
        // "authors": (value) => value is List<String> && value.isNotEmpty,
        "version": (value) => value is Version,
        "featureSets": (value) =>
            value is List<FeatureSets> && value.isNotEmpty,
        "archiveHash": (value) => value is String && value.isNotEmpty,
      };

  @override
  get optionalAttributes => {
        "developerUrl": (value) => value is String && value.isNotEmpty,
      };

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element(tag, attributes: {
          "name": attributes["name"], // The name of the addon
          "version": (attributes["version"] as Version)
              .toString(), // The version of the addon
          "sets": (attributes["featureSets"] // The feature sets to add
                  as List<FeatureSets>)
              .map<String>((e) => e.index.toString())
              .join(","),
        }, nest: () {
          DescriptionFactory() // The description of
              .creator(builder, {"text": attributes["description"]});
          SRArchiveFactory()
              .creator(builder, {"hash": attributes["archiveHash"]});
        });
      };
}

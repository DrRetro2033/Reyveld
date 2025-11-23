import '/security/policies/files/files.dart';
import '/security/policies/skit/skit.dart';
import '/skit/sobject.dart';
import '/skit/sobjects/sobjects.dart' show Whitelist, SDescription;
import 'package:yaml/yaml.dart';

import 'all/all.dart' show SPolicyAll, SPolicyAllCreator;

export '/skit/sobjects/sobjects.dart' show SDescription, Whitelist;

export 'package:yaml/yaml.dart';

part 'policy.interface.dart';

/// The safety level of a permission. This is used to comunicate to the user about the safety of the permission.
enum SPolicySafetyLevel { safe, warn, unsafe }

/// A base policy class.
/// All policies must extend this class.
///
/// [description] is a human-readable description of the permission, and it is used for explaing what the user is permitting the application to do.
/// For example, if a permission applies to SKits, it would most likely have the description "Allow the application to open, create, and edit SKits."
abstract class SPolicy extends SObject {
  SPolicy(super._node);
  String get reasoning =>
      getChild<SDescription>()?.text ?? "No reasoning provided.";
  String get description;
  SPolicySafetyLevel get safetyLevel;

  /// This is used to display the details of the policy to the user.
  String details() => """
## Permission
$description
## Reasoning
$reasoning
""";

  static Future<SPolicySKit> skit(
          {String? reasoning,
          bool read = false,
          bool write = false,
          bool create = false,
          bool delete = false}) async =>
      SPolicySKitCreator(
              reasoning: reasoning,
              read: read,
              write: write,
              init: create,
              delete: delete)
          .create();

  static Future<SPolicyFiles> files(
          {required Whitelist whitelist,
          String? reasoning,
          bool rexter = false,
          bool wexter = false,
          bool cexter = false,
          bool dexter = false,
          bool rinter = false,
          bool winter = false,
          bool cinter = false,
          bool dinter = false}) async =>
      SPolicyFilesCreator(
              reasoning: reasoning,
              readExternally: rexter,
              writeExternally: wexter,
              createExternally: cexter,
              deleteExternally: dexter,
              readInternally: rinter,
              writeInternally: winter,
              createInternally: cinter,
              deleteInternally: dinter,
              whitelist: whitelist)
          .create();

  static Future<SPolicyAll> all([String? reasoning]) async =>
      SPolicyAllCreator(reasoning: reasoning).create();

  static SPolicy fromYaml(YamlMap yaml) {
    final type = yaml["type"] as String;
    switch (type) {
      case "skit":
        return SPolicySKit.fromYaml(yaml);
      case "files":
        return SPolicyFiles.fromYaml(yaml);
      case "all":
        return SPolicyAll.fromYaml(yaml);
      default:
        throw Exception("Unknown policy type: $type.");
    }
  }
}

import 'package:reyveld/security/policies/files/files.dart';
import 'package:reyveld/security/policies/skit/skit.dart';
import 'package:reyveld/skit/sobject.dart';

import '../../skit/sobjects/file_system/filelist/filelist.dart';
import 'all/all.dart';

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
  String get description;
  SPolicySafetyLevel get safetyLevel;

  /// This is used to display the details of the policy to the user.
  void details(XmlBuilder builder);
}

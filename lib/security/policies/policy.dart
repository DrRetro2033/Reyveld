import 'package:arceus/security/policies/files/files.dart';
import 'package:arceus/security/policies/skit/skit.dart';
import 'package:arceus/skit/sobject.dart';

import '../../skit/sobjects/file_system/filelist/filelist.dart';
import 'all/all.dart';

part 'policy.interface.dart';

/// The types of permissions.
/// This is used to determine what a permission applies to.
/// Only the first [SPolicy] of a specific type will be used, as to avoid conflicts, and or overlaps of permissions.
enum SPermissionType {
  /// The permission to open SKits to read their contents.
  openSKits,

  /// The permission to edit SKits, including adding, removing, and modifying SObjects within the SKit.
  editSKits,

  /// The permission to create new SKits.
  createSKits,

  /// The permission to delete SKits.
  deleteSKits,

  /// The permission to read binary data from files.
  readFiles,

  /// The permission to write binary data to files outside of SKits.
  writeFiles,

  /// The permission to create files outside of SKits.
  createFiles,

  /// The permission to delete files outside of SKits.
  deleteFiles,

  /// The permission to open folders outside of SKits.
  openFolders,

  /// The permission to edit folders outside of SKits.
  editFolders,

  /// The permission to create folders outside of SKits.
  createFolders,

  /// The permission to delete folders outside of SKits.
  deleteFolders,
}

/// The safety level of a permission. This is used to comunicate to the user about the safety of the permission.
enum SPolicySafetyLevel { safe, warn, unsafe }

/// A base permission class.
/// All permissions must extend this class.
/// There are functions for each [SPermissionType], and every permission must override at least one of them to allow the application. function must return true for the permission to be granted.
/// So, for example, if a permission applies to SKits, it would have the types [SPermissionType.editSKits], [SPermissionType.openSKits], and [SPermissionType.createSKits] types.
///
/// [description] is a human-readable description of the permission, and it is used for explaing what the user is permitting the application to do.
/// For example, if a permission applies to SKits, it would most likely have the description "Allow the application to open, create, and edit SKits."
abstract class SPolicy extends SObject {
  SPolicy(super._node);
  String get description;
  SPolicySafetyLevel get safetyLevel;
  Map<SPermissionType, bool Function(Object)> get checks;

  bool isAllowed(SPermissionType type, Object toCheck) {
    final check = checks[type];
    if (check == null) return false;
    return check(toCheck);
  }

  void details(XmlBuilder builder);
}

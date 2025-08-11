import 'package:arceus/security/policies/policy.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';

part 'files.creator.dart';
part 'files.g.dart';
part 'files.interface.dart';

@SGen("polfiles")
class SPolicyFiles extends SPolicy {
  SPolicyFiles(super._node);

  bool get read => get("read") == "1";
  bool get write => get("write") == "1";
  bool get create => get("create") == "1";
  bool get delete => get("delete") == "1";

  Whitelist? get whitelist => getChild<Whitelist>();

  get safetyLevel {
    if (write || delete) {
      return SPolicySafetyLevel.unsafe;
    } else if (create) {
      return SPolicySafetyLevel.warn;
    } else {
      return SPolicySafetyLevel.safe;
    }
  }

  @override
  get checks => {
        SPermissionType.externalRead: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && read) {
            return whitelist?.included(toCheck.path) ?? false;
          }
          return false;
        },
        SPermissionType.externalWrite: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && write) {
            return whitelist?.included(toCheck.path) ?? false;
          }
          return false;
        },
        SPermissionType.createFiles: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && create) {
            return whitelist?.included(toCheck.path) ?? false;
          }
          return false;
        },
        SPermissionType.deleteFiles: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && delete) {
            return whitelist?.included(toCheck.path) ?? false;
          }
          return false;
        },
      };

  @override
  get description {
    final x = [(read, "read"), (write, "write"), (create, "create")];
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} external files.";
  }
}

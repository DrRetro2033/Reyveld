import 'package:arceus/extensions.dart';
import 'package:arceus/security/policies/policy.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';

part 'files.creator.dart';
part 'files.g.dart';
part 'files.interface.dart';

@SGen("polexterfiles")
class SPolicyExterFiles extends SPolicy {
  SPolicyExterFiles(super._node);

  bool get read => get("read") == "1";
  bool get write => get("write") == "1";
  bool get create => get("create") == "1";
  bool get delete => get("delete") == "1";

  Whitelist? get whitelist => getChild<Whitelist>();

  @override
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
        SPermissionType.readFiles: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && read) {
            return whitelist?.included(toCheck.path.getFilename()) ?? false;
          }
          return false;
        },
        SPermissionType.writeFiles: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && write) {
            return whitelist?.included(toCheck.path.getFilename()) ?? false;
          }
          return false;
        },
        SPermissionType.createFiles: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && create) {
            return whitelist?.included(toCheck.path.getFilename()) ?? false;
          }
          return false;
        },
        SPermissionType.deleteFiles: (Object toCheck) {
          if (toCheck is SFile && toCheck.isExternal && delete) {
            return whitelist?.included(toCheck.path.getFilename()) ?? false;
          }
          return false;
        },
      };

  @override
  get description {
    final x = [
      (read, "read"),
      (write, "write"),
      (create, "create"),
      (delete, "delete")
    ];
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} external files.";
  }

  @override
  void details(XmlBuilder builder) {
    final x = [
      (read, "read"),
      (write, "write"),
      (create, "create"),
      (delete, "delete")
    ];
    builder.element("h2",
        nest: () => builder.text(
            "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} the following external files:"));
    builder.element("ul", nest: () {
      for (final glob in whitelist!.globs) {
        builder.element("li", nest: () => builder.text(glob.pattern));
      }
    });
  }
}

@SGen("polinterfiles")
class SPolicyInterFiles extends SPolicy {
  SPolicyInterFiles(super._node);

  bool get read => get("read") == "1";
  bool get write => get("write") == "1";
  bool get create => get("create") == "1";
  bool get delete => get("delete") == "1";

  @override
  get safetyLevel => SPolicySafetyLevel.safe;

  @override
  get checks => {
        SPermissionType.readFiles: (Object toCheck) =>
            toCheck is SFile && !toCheck.isExternal && read,
        SPermissionType.writeFiles: (Object toCheck) =>
            toCheck is SFile && !toCheck.isExternal && write,
        SPermissionType.createFiles: (Object toCheck) =>
            toCheck is SFile && !toCheck.isExternal && create,
        SPermissionType.deleteFiles: (Object toCheck) =>
            toCheck is SFile && !toCheck.isExternal && delete
      };

  @override
  get description {
    final x = [
      (read, "read"),
      (write, "write"),
      (create, "create"),
      (delete, "delete")
    ];
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} internal files (i.e. Inside SKits).";
  }

  @override
  void details(XmlBuilder builder) {
    final x = [
      (read, "read"),
      (write, "write"),
      (create, "create"),
      (delete, "delete")
    ];
    builder.element("h2",
        nest: () => builder.text(
            "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} every files inside of SKits."));
  }
}

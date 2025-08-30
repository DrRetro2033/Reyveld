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

  bool readAllowed(String filepath) => read && whitelist!.included(filepath);

  bool writeAllowed(String filepath) => write && whitelist!.included(filepath);

  bool createAllowed(String filepath) =>
      create && whitelist!.included(filepath);

  bool deleteAllowed(String filepath) =>
      delete && whitelist!.included(filepath);

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

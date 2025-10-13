import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:reyveld/skit/sobjects/sobjects.dart';

part 'files.creator.dart';
part 'files.g.dart';
part 'files.interface.dart';

@SGen("polexterfiles")
class SPolicyExterFiles extends SPolicy {
  SPolicyExterFiles(super._node);

  @override
  childAllowed(object) {
    if (object is Whitelist) {
      return (true, "");
    }
    return (false, "Cannot add a ${object.runtimeType} to an $runtimeType!");
  }

  bool get _read => get("read") == "1";
  bool get _write => get("write") == "1";
  bool get _create => get("create") == "1";
  bool get _delete => get("delete") == "1";

  Whitelist? get whitelist => getChild<Whitelist>();

  bool readAllowed(String filepath) => _read && whitelist!.included(filepath);

  bool writeAllowed(String filepath) => _write && whitelist!.included(filepath);

  bool createAllowed(String filepath) =>
      _create && whitelist!.included(filepath);

  bool deleteAllowed(String filepath) =>
      _delete && whitelist!.included(filepath);

  @override
  get safetyLevel {
    if (_write || _delete) {
      return SPolicySafetyLevel.unsafe;
    } else if (_create) {
      return SPolicySafetyLevel.warn;
    } else {
      return SPolicySafetyLevel.safe;
    }
  }

  @override
  get description {
    final x = [
      (_read, "read"),
      (_write, "write"),
      (_create, "create"),
      (_delete, "delete")
    ];
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} external files.";
  }

  @override
  String details() {
    final x = [
      (_read, "read"),
      (_write, "write"),
      (_create, "create"),
      (_delete, "delete")
    ];
    return """
## Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} the following external files:
${whitelist!.globs.map((e) => "- ${e.pattern}").join("\n")}
""";
  }
}

@SGen("polinterfiles")
class SPolicyInterFiles extends SPolicy {
  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;
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
  String details() {
    final x = [
      (read, "read"),
      (write, "write"),
      (create, "create"),
      (delete, "delete")
    ];
    return "## Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} every files inside of SKits.";
  }
}

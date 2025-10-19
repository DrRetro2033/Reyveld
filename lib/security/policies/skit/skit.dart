import 'package:reyveld/extensions.dart';
import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/skit/skit.dart';

part 'skit.g.dart';
part 'skit.creator.dart';
part 'skit.interface.dart';

@SGen("polskit")
class SPolicySKit extends SPolicy {
  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;
  static const Set<String> _protectedSKits = {
    "authveld.skit",
    "trusted_authors.skit"
  };
  SPolicySKit(super._node);

  bool get _read => get("read") == "1";
  bool get _write => get("write") == "1";
  bool get _create => get("create") == "1";
  bool get _delete => get("delete") == "1";

  bool isProtectedSKit(String path) {
    if (_protectedSKits.contains(path.getFilename())) {
      return true;
    }
    return false;
  }

  bool readAllowed(String path) {
    if (isProtectedSKit(path)) {
      return false;
    }
    return _read;
  }

  bool writeAllowed(String path) {
    if (isProtectedSKit(path)) {
      return false;
    }
    return _write;
  }

  bool createAllowed(String path) {
    if (isProtectedSKit(path)) {
      return false;
    }
    return _create;
  }

  bool deleteAllowed(String path) {
    if (isProtectedSKit(path)) {
      return false;
    }
    return _delete;
  }

  @override
  get safetyLevel => SPolicySafetyLevel.safe;

  @override
  get description {
    final x = [
      (_read, "read"),
      (_write, "write"),
      (_create, "create"),
      (_delete, "delete")
    ];
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} SKits.";
  }

  @override
  String details() => description;
}

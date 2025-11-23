import '/extensions.dart';
import '/security/policies/policy.dart';
import '/skit/skit.dart';
import '/skit/sobjects/description/description.dart';

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

  static SPolicySKit fromYaml(YamlMap yaml) {
    final actions = yaml["actions"] as YamlList;
    final read = actions.contains("read");
    final write = actions.contains("write");
    final create = actions.contains("create");
    final delete = actions.contains("delete");
    return SPolicySKitCreator(
            read: read, write: write, init: create, delete: delete)
        .create();
  }
}

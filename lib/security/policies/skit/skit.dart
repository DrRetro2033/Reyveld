import 'package:arceus/security/policies/policy.dart';
import 'package:arceus/skit/skit.dart';

part 'skit.g.dart';
part 'skit.creator.dart';
part 'skit.interface.dart';

@SGen("polskit")
class SPolicySKit extends SPolicy {
  SPolicySKit(super._node);

  bool get read => get("read") == "1";
  bool get write => get("write") == "1";
  bool get create => get("create") == "1";
  bool get delete => get("delete") == "1";

  @override
  get checks => {
        SPermissionType.openSKits: (Object toCheck) {
          if (toCheck is SKit) return read;
          return false;
        },
        SPermissionType.editSKits: (Object toCheck) {
          if (toCheck is SKit) return write;
          return false;
        },
        SPermissionType.createSKits: (Object toCheck) {
          if (toCheck is SKit) return create;
          return false;
        },
        SPermissionType.deleteSKits: (Object toCheck) {
          if (toCheck is SKit) return delete;
          return false;
        }
      };

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
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} SKits.";
  }
}

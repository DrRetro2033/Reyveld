import 'package:arceus/extensions.dart';
import 'package:arceus/security/policies/policy.dart';
import 'package:arceus/skit/skit.dart';

part 'skit.g.dart';
part 'skit.creator.dart';
part 'skit.interface.dart';

@SGen("polskit")
class SPolicySKit extends SPolicy {
  static const Set<String> _protectedSKits = {"authveld.skit"};
  SPolicySKit(super._node);

  bool get read => get("read") == "1";
  bool get write => get("write") == "1";
  bool get create => get("create") == "1";
  bool get delete => get("delete") == "1";

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
    return read;
  }

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

  @override
  void details(XmlBuilder builder) =>
      builder.element("h2", nest: () => builder.text(description));
}

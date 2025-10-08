import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/skit/skit.dart';

part 'launch_apps.creator.dart';
part 'launch_apps.g.dart';
part 'launch_apps.interface.dart';

@SGen("lapps")
class SPolicyLaunchApps extends SPolicy {
  SPolicyLaunchApps(super._node);

  @override
  (bool, String) childAllowed(SObject object) => SObject.zeroChildrenAllowed;
  @override
  String get description => "Launch Apps.";

  @override
  String details() => """
## Allow the application to launch an app with a file as an argument.
""";

  @override
  SPolicySafetyLevel get safetyLevel => SPolicySafetyLevel.warn;
}

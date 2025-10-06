import 'package:reyveld/skit/sobject.dart';

import '../policy.dart';

part 'all.g.dart';
part 'all.creator.dart';
part 'all.interface.dart';

@SGen("polall")
class SPolicyAll extends SPolicy {
  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;
  SPolicyAll(super._node);

  @override
  get safetyLevel => SPolicySafetyLevel.unsafe;

  @override
  get description => "Give all permissions to this application.";

  @override
  String details() => "## $description";
}

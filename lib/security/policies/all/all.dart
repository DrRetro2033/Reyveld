import '/skit/sobject.dart';

import '/security/policies/policy.dart';
import '/skit/sobjects/sobjects.dart' show SDescriptionCreator;

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

  static SPolicyAll fromYaml(YamlMap yaml) => SPolicyAllCreator().create();
}

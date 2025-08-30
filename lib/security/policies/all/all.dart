import 'package:arceus/skit/sobject.dart';

import '../policy.dart';

part 'all.g.dart';
part 'all.creator.dart';
part 'all.interface.dart';

@SGen("polall")
class SPolicyAll extends SPolicy {
  SPolicyAll(super._node);

  @override
  get safetyLevel => SPolicySafetyLevel.unsafe;

  @override
  get description => "Give all permissions to this application.";

  @override
  void details(XmlBuilder builder) =>
      builder.element("h2", nest: () => builder.text(description));
}

import '/skit/sobject.dart';

part 'description.g.dart';
part 'description.creator.dart';

/// This [SObject] is used for descriptions of things in the kit file.

@SGen("descr")
class SDescription extends SObject {
  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;

  String get text => cdataString!;

  SDescription(super._node);
}

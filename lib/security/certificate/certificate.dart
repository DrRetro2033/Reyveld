import 'package:arceus/security/policies/policies.dart';
import 'package:arceus/skit/sobject.dart';

part 'certificate.g.dart';
part 'certificate.interface.dart';
part 'certificate.creator.dart';

@SGen("cert")
class SCertificate extends SObject {
  SCertificate(super._node);
}

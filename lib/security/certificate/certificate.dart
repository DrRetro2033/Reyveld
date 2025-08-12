import 'package:arceus/security/authveld.dart';
import 'package:arceus/security/policies/policies.dart';
import 'package:arceus/skit/sobject.dart';

part 'certificate.g.dart';
part 'certificate.interface.dart';
part 'certificate.creator.dart';

@SGen("cert")
class SCertificate extends SRoot {
  SCertificate(super._node);

  List<SPolicy> get policies =>
      getChildren<SPolicy>().whereType<SPolicy>().toList();

  /// Throws an [AuthVeldException] if no policy allows access.
  void permitted(SPermissionType type, Object toCheck) {
    for (final policy in policies) {
      if (policy.isAllowed(type, toCheck)) {
        return;
      }
    }
    throw AuthVeldException("Access denied.");
  }

  /// If any policy allows access, allow access.
  bool isAllowed(SPermissionType type, Object toCheck) =>
      policies.any((element) => element.isAllowed(type, toCheck));

  @override
  Future<SIndent<SRoot>> newIndent() async =>
      await SISCertificateCreator(hash).create();
}

class SCertificateIndent extends SIndent<SCertificate> {
  SCertificateIndent(super.hash);
}

typedef SISCertificateCreator = SIndentCreator<SCertificateIndent>;

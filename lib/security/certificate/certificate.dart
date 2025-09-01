import 'package:reyveld/security/policies/policies.dart';
import 'package:reyveld/skit/sobject.dart';

part 'certificate.g.dart';
part 'certificate.interface.dart';
part 'certificate.creator.dart';

@SGen("cert")
class SCertificate extends SRoot {
  SCertificate(super._node);

  List<SPolicy> get policies =>
      getChildren<SPolicy>().whereType<SPolicy>().toList();

  bool get completeAccess => policies.any((policy) => policy is SPolicyAll);

  T? getPolicy<T extends SPolicy>() => policies.whereType<T>().firstOrNull;

  @override
  Future<SIndent<SRoot>> newIndent() async =>
      await SISCertificateCreator(hash).create();
}

class SCertificateIndent extends SIndent<SCertificate> {
  SCertificateIndent(super.hash);
}

/// Creates [SCertificateIndent]s.
typedef SISCertificateCreator = SIndentCreator<SCertificateIndent>;

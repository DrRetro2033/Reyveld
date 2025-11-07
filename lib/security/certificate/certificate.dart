import 'package:chalkdart/chalkstrings.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/security/policies/policies.dart';
import 'package:reyveld/skit/sobject.dart';

part 'certificate.g.dart';
part 'certificate.interface.dart';
part 'certificate.creator.dart';

@SGen("cert")
class SCertificate extends SRoot {
  @override
  childAllowed(object) {
    if (object is SPolicy) {
      return (true, "");
    }
    return (false, "Cannot add a ${object.runtimeType} to an $runtimeType!");
  }

  SCertificate(super._node);

  /// Returns the polices of the [SCertificate].
  List<SPolicy> get policies =>
      getChildren<SPolicy>().whereType<SPolicy>().toList();

  /// Returns true if the [SCertificate] has the [SPolicyAll] policy.
  bool get completeAccess => policies.any((policy) => policy is SPolicyAll);

  /// Returns the application name.
  String get appname => get("appname") ?? "Default";

  /// Is the certificate authorized?
  /// The user may authorize or deauthorize a certificate at any time.
  bool get authorized => (get("authorized") ?? "1") == "1";
  set authorized(bool value) => set("authorized", value ? "1" : "0");

  T? getPolicy<T extends SPolicy>() => policies.whereType<T>().firstOrNull;

  Iterable<T?> getPolicies<T extends SPolicy>() => policies.whereType<T>();

  bool hasPolicy<T extends SPolicy>() => getPolicy<T>() != null;

  @override
  Future<SIndent<SRoot>> newIndent() async =>
      await SISCertificateCreator(id).create();

  String toDisplayString() =>
      "Certificate for '$appname' | '$id' | ${policies.length} policies | ${authorized ? "Authorized".green : "Deauthorized".red}";

  void deauthorize() => authorized = false;
  void reauthorize() => authorized = true;
}

class SCertificateIndent extends SIndent<SCertificate> {
  SCertificateIndent(super.hash);
}

/// Creates [SCertificateIndent]s.
typedef SISCertificateCreator = SIndentCreator<SCertificateIndent>;

import 'package:chalkdart/chalkstrings.dart';
import '/reyveld.dart';
import '/security/policies/policies.dart';
import '/skit/sobject.dart';

part 'contract.g.dart';
part 'contract.interface.dart';
part 'contract.creator.dart';

@SGen("cert")
class SContract extends SRoot {
  @override
  childAllowed(object) {
    if (object is SPolicy) {
      return (true, "");
    }
    return (false, "Cannot add a ${object.runtimeType} to an $runtimeType!");
  }

  SContract(super._node);

  /// Returns the polices of the [SContract].
  List<SPolicy> get policies =>
      getChildren<SPolicy>().whereType<SPolicy>().toList();

  /// Returns true if the [SContract] has the [SPolicyAll] policy.
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
  Future<SIndent<SRoot>> newIndent() async => SISContractCreator(id).create();

  String toDisplayString() =>
      "Contract for '$appname' | '$id' | ${policies.length} policies | ${authorized ? "Authorized".green : "Deauthorized".red}";

  void deauthorize() => authorized = false;
  void reauthorize() => authorized = true;

  /// Returns true if the [SContract] has all the [SPolicy]s in the [policies] list.
  bool verify(List<SPolicy> policies) => policies
      .map((e) => e.checksum)
      .every((policy) => this.policies.map((e) => e.checksum).contains(policy));

  static SContract fromYaml(YamlMap yaml) {
    final appname = yaml["appname"] as String;
    final policies = yaml["policies"] as YamlList;
    final finalPolicies = <SPolicy>[];
    for (final YamlMap policy in policies) {
      finalPolicies.add(SPolicy.fromYaml(policy));
    }
    return SContractCreator(appname, finalPolicies).create();
  }
}

@SGen("rcert")
class SContractIndent extends SIndent<SContract> {
  SContractIndent(super.hash);
}

/// Creates [SContractIndent]s.
typedef SISContractCreator = SIndentCreator<SContractIndent>;

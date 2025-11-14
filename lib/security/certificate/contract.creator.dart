part of 'contract.dart';

class SContractCreator extends SCreator<SContract> {
  final String appname;
  final List<SPolicy> policies;

  SContractCreator(this.appname, this.policies);

  @override
  build(builder) {
    for (final policy in policies) {
      builder.attribute("appname", appname);
      builder.sobject(policy);
    }
  }
}

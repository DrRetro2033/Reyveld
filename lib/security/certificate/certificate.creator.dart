part of 'certificate.dart';

class SCertificateCreator extends SCreator<SCertificate> {
  final String appname;
  final List<SPolicy> policies;

  SCertificateCreator(this.appname, this.policies);

  @override
  get creator => (builder) {
        for (final policy in policies) {
          builder.attribute("appname", appname);
          builder.sobject(policy);
        }
      };
}

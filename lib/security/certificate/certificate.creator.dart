part of 'certificate.dart';

class SCertificateCreator extends SCreator<SCertificate> {
  final List<SPolicy> policies;

  SCertificateCreator(this.policies);

  @override
  get creator => (builder) {
        for (final policy in policies) {
          builder.sobject(policy);
        }
      };
}

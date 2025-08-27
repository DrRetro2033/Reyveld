part of 'certificate.dart';

class SCertificateInterface extends SInterface<SCertificate> {
  @override
  get className => "SCertificate";

  @override
  get exports => {
        LEntry(
            name: "policies",
            descr: "The policies of the certificate.",
            returnType: List,
            () => object!.policies)
      };
}

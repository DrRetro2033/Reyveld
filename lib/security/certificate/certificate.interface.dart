part of 'certificate.dart';

class SCertificateInterface extends SInterface<SCertificate> {
  @override
  get className => "SCertificate";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
            name: "empty",
            descr:
                "Creates an empty certificate. Used for testing sercurity checks.",
            returnType: SCertificate,
            () => SCertificateCreator("", []).create())
      };

  @override
  get exports => {
        LEntry(
            name: "policies",
            descr: "The policies of the certificate.",
            returnType: List,
            () => object!.policies),
        LEntry(
            name: "getPolicyByType",
            descr: "Gets a policy by type.",
            returnType: SPolicy,
            returnGeneric: true,
            returnNullable: true,
            args: const {
              LArg<SInterface>(
                  name: "type",
                  descr: "The type of the policy.",
                  docTypeOverride: "table")
            }, (SInterface type) {
          Reyveld.talker.info(type);
          return object!.getChildren().firstWhere((e) => type.isType(e));
        }),
        LEntry(
            name: "hasPolicy",
            descr: "Checks if the certificate has a policy of a certain type.",
            returnType: bool,
            args: const {
              LArg<SInterface>(
                  name: "type",
                  descr: "The type of the policy.",
                  docTypeOverride: "table")
            }, (SInterface type) {
          Reyveld.talker.info(type);
          return object!
              .getChildren<SPolicy>()
              .any((e) => e != null ? type.isType(e) : false);
        }),
      };
}

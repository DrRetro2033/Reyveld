part of 'contract.dart';

class SContractInterface extends SInterface<SContract> {
  @override
  get className => "SContract";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
            name: "empty",
            descr:
                "Creates an empty contract. Used as a dummy contract for testing security checks, if no contract is provided.",
            returnType: SContract,
            () => SContractCreator("", []).create())
      };

  @override
  get exports => {
        LEntry(
            name: "policies",
            descr: "The policies of the certificate.",
            returnType: List,
            () => object!.policies),
        LEntry(
            name: "getPolicy",
            descr: "Returns a policy with the specific type and/or filter.",
            returnType: SPolicy,
            returnGeneric: true,
            returnNullable: true,
            args: const {
              LArg<SInterface>(
                  name: "type",
                  descr: "The type of the policy.",
                  docTypeOverride: "table",
                  kind: ArgKind.optionalNamed),
              LArg<LuaFuncRef>(
                  name: "filter",
                  descr: "The filter to use.",
                  docTypeOverride: "function",
                  kind: ArgKind.optionalNamed)
            }, ({SInterface? type, LuaFuncRef? filter}) async {
          for (final policy in object!.policies) {
            if (type != null && !type.isType(policy)) continue;
            if (filter != null && !await filter.call([policy])) continue;
            return policy;
          }
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

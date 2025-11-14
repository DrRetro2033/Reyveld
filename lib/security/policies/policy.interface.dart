part of 'policy.dart';

class SPolicyInterface extends SInterface<SPolicy> {
  @override
  get className => "SPolicy";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
            name: "skits",
            descr: "The SKits policy.",
            returnType: SPolicySKit,
            args: const {
              LArg<String>(
                  name: "reasoning",
                  descr: "The reasoning behind the policy.",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "null"),
              LArg<bool>(
                  name: "read",
                  descr: "Require permission to read SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "write",
                  descr: "Require permission to write SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "create",
                  descr: "Require permission to create new SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "delete",
                  descr: "Require permission to delete SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
            },
            (
                    {String? reasoning,
                    bool read = false,
                    bool write = false,
                    bool create = false,
                    bool delete = false}) =>
                SPolicy.skit(
                    reasoning: reasoning,
                    read: read,
                    write: write,
                    create: create,
                    delete: delete)),
        LEntry(
            name: "files",
            descr: "The files policy.",
            returnType: SPolicyFiles,
            args: const {
              LArg<Whitelist>(
                  name: "whitelist",
                  descr: "The whitelist to use.",
                  kind: ArgKind.requiredNamed),
              LArg<String>(
                  name: "reasoning",
                  descr: "The reasoning behind the policy.",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "null"),
              LArg<bool>(
                  name: "rexter",
                  descr: "Require permission to read external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "wexter",
                  descr: "Require permission to write external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "cexter",
                  descr: "Require permission to create external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "dexter",
                  descr: "Require permission to delete external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "rinter",
                  descr: "Require permission to read internal files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "winter",
                  descr: "Require permission to write internal files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "cinter",
                  descr: "Require permission to create internal files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "dinter",
                  descr: "Require permission to delete internal files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
            },
            (
                    {required Whitelist whitelist,
                    String? reasoning,
                    bool rexter = false,
                    bool wexter = false,
                    bool cexter = false,
                    bool dexter = false,
                    bool rinter = false,
                    bool winter = false,
                    bool cinter = false,
                    bool dinter = false}) =>
                SPolicy.files(
                    whitelist: whitelist,
                    reasoning: reasoning,
                    rexter: rexter,
                    wexter: wexter,
                    cexter: cexter,
                    dexter: dexter,
                    rinter: rinter,
                    winter: winter,
                    cinter: cinter,
                    dinter: dinter)),
        LEntry(
            name: "all",
            descr: "The all policy.",
            args: const {
              LArg<String>(
                  name: "reasoning",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "null"),
            },
            returnType: SPolicyAll,
            ({String? reasoning}) => SPolicy.all(reasoning)),
      };
}

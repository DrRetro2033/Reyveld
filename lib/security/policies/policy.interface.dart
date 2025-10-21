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
                    {bool read = false,
                    bool write = false,
                    bool create = false,
                    bool delete = false}) =>
                SPolicySKitCreator(
                        read: read, write: write, init: create, delete: delete)
                    .create()),
        LEntry(
            name: "all",
            descr: "The all policy.",
            returnType: SPolicyAll,
            () => SPolicyAllCreator().create()),
      };
}

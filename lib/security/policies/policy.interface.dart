part of 'policy.dart';

class SPolicyInterface extends SInterface<SPolicy> {
  @override
  String get className => "SPolicy";

  @override
  get statics => {
        LEntry(
            name: "skit",
            descr: "The SKit policy.",
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
            name: "externalFiles",
            descr: "The external files policy.",
            returnType: SPolicyExterFiles,
            args: const {
              LArg<bool>(
                  name: "read",
                  descr: "Require permission to read external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "write",
                  descr: "Require permission to write external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "create",
                  descr: "Require permission to create external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "delete",
                  descr: "Require permission to delete external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<Whitelist>(
                  name: "whitelist",
                  descr: "The whitelist of files to allow access to.",
                  kind: ArgKind.requiredNamed),
            },
            (
                    {bool read = false,
                    bool write = false,
                    bool create = false,
                    bool delete = false,
                    required Whitelist whitelist}) =>
                SPolicyExterFilesCreator(
                        read: read,
                        write: write,
                        init: create,
                        delete: delete,
                        whitelist: whitelist)
                    .create()),
        LEntry(
            name: "internalFiles",
            descr: "The internal files policy.",
            returnType: SPolicyInterFiles,
            args: const {
              LArg<bool>(
                  name: "read",
                  descr: "Require permission to read files inside of SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "write",
                  descr: "Require permission to write files inside of SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "create",
                  descr: "Require permission to create files inside of SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              LArg<bool>(
                  name: "delete",
                  descr: "Require permission to delete files inside of SKits?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
            },
            ({
              bool read = false,
              bool write = false,
              bool create = false,
              bool delete = false,
            }) =>
                SPolicyInterFilesCreator(
                  read: read,
                  write: write,
                  init: create,
                  delete: delete,
                ).create()),
        LEntry(
            name: "all",
            descr: "The all policy.",
            returnType: SPolicyAll,
            () => SPolicyAllCreator().create()),
      };
}

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
              "read": LArg<bool>(
                  descr: "Require permission to read SKit files?",
                  kind: ArgKind.requiredNamed),
              "write": LArg<bool>(
                  descr: "Require permission to write SKit files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "create": LArg<bool>(
                  descr: "Require permission to create SKit files?",
                  kind: ArgKind.requiredNamed),
              "delete": LArg<bool>(
                  descr: "Require permission to delete SKit files?",
                  kind: ArgKind.requiredNamed),
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
              "read": LArg<bool>(
                  descr: "Require permission to read external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "write": LArg<bool>(
                  descr: "Require permission to write external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "create": LArg<bool>(
                  descr: "Require permission to create external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "delete": LArg<bool>(
                  descr: "Require permission to delete external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "whitelist": LArg<Whitelist>(
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
              "read": LArg<bool>(
                  descr: "Require permission to read external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "write": LArg<bool>(
                  descr: "Require permission to write external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "create": LArg<bool>(
                  descr: "Require permission to create external files?",
                  kind: ArgKind.optionalNamed,
                  docDefaultValue: "false"),
              "delete": LArg<bool>(
                  descr: "Require permission to delete external files?",
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

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
                  kind: ArgKind.requiredNamed),
              "create": LArg<bool>(
                  descr: "Require permission to create SKit files?",
                  kind: ArgKind.requiredNamed),
              "delete": LArg<bool>(
                  descr: "Require permission to delete SKit files?",
                  kind: ArgKind.requiredNamed),
            },
            (
                    {required bool read,
                    required bool write,
                    required bool create,
                    required bool delete}) =>
                SPolicySKitCreator(
                        read: read, write: write, init: create, delete: delete)
                    .create()),
        LEntry(
            name: "files",
            descr: "The files policy.",
            returnType: SPolicySKit,
            args: const {
              "read": LArg<bool>(
                  descr: "Require permission to read external files?",
                  kind: ArgKind.requiredNamed),
              "write": LArg<bool>(
                  descr: "Require permission to write external files?",
                  kind: ArgKind.requiredNamed),
              "create": LArg<bool>(
                  descr: "Require permission to create external files?",
                  kind: ArgKind.requiredNamed),
              "delete": LArg<bool>(
                  descr: "Require permission to delete external files?",
                  kind: ArgKind.requiredNamed),
              "whitelist": LArg<Whitelist>(
                  descr: "The whitelist of files to allow access to.",
                  kind: ArgKind.requiredNamed),
            },
            (
                    {required bool read,
                    required bool write,
                    required bool create,
                    required bool delete,
                    required Whitelist whitelist}) =>
                SPolicyFilesCreator(
                        read: read,
                        write: write,
                        init: create,
                        delete: delete,
                        whitelist: whitelist)
                    .create()),
        LEntry(
            name: "all",
            descr: "The all policy.",
            returnType: SPolicyAll,
            () => SPolicyAllCreator().create()),
      };
}

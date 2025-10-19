part of 'skit.dart';

class SPolicySKitInterface extends SInterface<SPolicySKit> {
  @override
  get className => "SPolicySKit";

  @override
  get parent => SPolicyInterface();

  @override
  get statics => {tagEntry(SPolicySKitFactory())};

  @override
  get exports => {
        LEntry(
            name: "readAllowed",
            descr: "Check if reading to a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            (String path) => object!.readAllowed(path)),
        LEntry(
            name: "writeAllowed",
            descr: "Check if writing to a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            (String path) => object!.writeAllowed(path)),
        LEntry(
            name: "createAllowed",
            descr: "Check if creating a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            (String path) => object!.createAllowed(path)),
        LEntry(
            name: "deleteAllowed",
            descr: "Check if deleting a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            (String path) => object!.deleteAllowed(path)),
      };
}

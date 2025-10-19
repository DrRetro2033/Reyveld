part of 'files.dart';

class SPolicyExterFilesInterface extends SInterface<SPolicyExterFiles> {
  @override
  get className => "SPolicyExterFiles";

  @override
  get parent => SPolicyInterface();

  @override
  get statics => {tagEntry(SPolicyExterFilesFactory())};

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

class SPolicyInterFilesInterface extends SInterface<SPolicyInterFiles> {
  @override
  get className => "SPolicyInterFiles";

  @override
  get parent => SPolicyInterface();

  @override
  get statics => {tagEntry(SPolicyInterFilesFactory())};

  @override
  get exports => {
        LEntry(
            name: "readAllowed",
            descr: "Check if reading a Internal file is allowed.",
            returnType: bool,
            () => object!.read),
        LEntry(
            name: "writeAllowed",
            descr: "Check if writing to a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            () => object!.write),
        LEntry(
            name: "createAllowed",
            descr: "Check if creating a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            () => object!.create),
        LEntry(
            name: "deleteAllowed",
            descr: "Check if deleting a SKit is allowed.",
            returnType: bool,
            args: const {
              LArg<String>(name: "path", descr: "The path to the SKit.")
            },
            () => object!.delete),
      };
}

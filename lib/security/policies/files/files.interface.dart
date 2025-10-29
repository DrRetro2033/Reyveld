// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'files.dart';

// **************************************************************************
// SInterfaceGenerator
// **************************************************************************

class SPolicyFilesInterface extends SInterface<SPolicyFiles> {
  @override
  get className => "SPolicyFiles";

  @override
  get classDescription => """The policy for files.""";
  @override
  get parent => SPolicyInterface();

  @override
  get statics => {};

  @override
  get exports => {
        LEntry(
            name: "readAllowed",
            descr: """Returns whether or not the file is allowed to be read.""",
            returnType: bool,
            args: const {
              LArg<String>(
                  name: "filepath",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<bool>(
                  name: "isExternal",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "boolean")
            }, (String filepath, bool isExternal) {
          return object!.readAllowed(filepath, isExternal);
        }),
        LEntry(
            name: "writeAllowed",
            descr:
                """Returns whether or not the file is allowed to be written.""",
            returnType: bool,
            args: const {
              LArg<String>(
                  name: "filepath",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<bool>(
                  name: "isExternal",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "boolean")
            }, (String filepath, bool isExternal) {
          return object!.writeAllowed(filepath, isExternal);
        }),
        LEntry(
            name: "createAllowed",
            descr:
                """Returns whether or not the file is allowed to be created.""",
            returnType: bool,
            args: const {
              LArg<String>(
                  name: "filepath",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<bool>(
                  name: "isExternal",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "boolean")
            }, (String filepath, bool isExternal) {
          return object!.createAllowed(filepath, isExternal);
        }),
        LEntry(
            name: "deleteAllowed",
            descr:
                """Returns whether or not the file is allowed to be deleted.""",
            returnType: bool,
            args: const {
              LArg<String>(
                  name: "filepath",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<bool>(
                  name: "isExternal",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "boolean")
            }, (String filepath, bool isExternal) {
          return object!.deleteAllowed(filepath, isExternal);
        }),
        LEntry(
            name: "isFileAssociated",
            descr:
                "Returns true if the filepath is associated with this policy.",
            returnType: bool,
            args: const {LArg<String>(name: "filepath")}, (String filepath) {
          return object!.isFileAssociated(filepath);
        }),
      };
}

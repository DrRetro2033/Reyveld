part of 'file_system.dart';

final class SArchiveInterface extends SInterface<SArchive> {
  @override
  get className => "SArchive";

  @override
  get classDescription => """
An archive in a SKit. Contains files.
""";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        tagEntry(SArchiveFactory()),
      };

  @override
  get exports => {
        LEntry(
            name: "filepaths",
            descr: "Returns the filepaths of the files in the archive",
            returnType: List,
            () => object!.getFiles().map<String>((e) => e!.path).toList()),
        LEntry(
            name: "files",
            descr: "Returns the files in the archive",
            returnType: List,
            () => object!.getFiles()),
        LEntry(
            name: "getFile",
            descr: "Returns the file with the path provided",
            args: {
              LArg<String>(
                name: "path",
                descr: "The path of the file",
              )
            },
            returnType: SFile,
            (String name) async => object!.getFile(name)),
        LEntry(
            name: "extract",
            descr: "Extracts the archive to the specified path",
            args: const {
              LArg<String>(
                name: "path",
                descr: "The path to extract the archive to",
              ),
            },
            isAsync: true,
            (String path) async =>
                await object!.extract(path).listen((state) {}).asFuture()),
      };
}

final class SFileInterface extends SInterface<SFile> {
  @override
  get className => "SFile";

  @override
  get classDescription => """
A file either stored on disk or in an SArchive. Contains the path of the file, and its data in the form of compressed base64.
""";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        tagEntry(SFileFactory()),
        LEntry(
            name: "open",
            descr: "Opens a file externally.",
            returnType: SFile,
            args: const {
              LArg<String>(
                name: "path",
                descr: "The path to open the file at.",
              )
            },
            isAsync: true, (path) async {
          return await SFileCreator.open(path);
        }),
      };

  /// The default read check for files.
  bool readCheck(SCertificate cert, LuaArgs args) {
    if (object!.isExternal) {
      if (cert.getPolicy<SPolicyExterFiles>()?.readAllowed(object!.path) ??
          false) {
        return true;
      }
    } else {
      if (cert.getPolicy<SPolicyInterFiles>()?.read ?? false) {
        return true;
      }
    }
    return false;
  }

  /// The default write check for files.
  bool writeCheck(SCertificate cert, LuaArgs args) {
    if (object!.isExternal) {
      if (cert.getPolicy<SPolicyExterFiles>()?.writeAllowed(object!.path) ??
          false) {
        return true;
      }
    } else {
      if (cert.getPolicy<SPolicyInterFiles>()?.write ?? false) {
        return true;
      }
    }
    return false;
  }

  @override
  get exports => {
        LEntry(
            name: "path",
            descr: "Returns the path of the file",
            returnType: String,
            () => object!.path),
        LEntry(
          name: "filename",
          descr: "Returns the filename of the file",
          returnType: String,
          args: const {
            LArg<bool>(
                name: "extension",
                descr:
                    "Whether to include the file extension in the filename. (default: true)",
                kind: ArgKind.optionalNamed)
          },
          ({bool extension = true}) =>
              object!.path.getFilename(withExtension: extension),
        ),
        LEntry(
            name: "checksum",
            descr: "Returns the checksum of the file",
            returnType: String,
            () => object!.checksum),
        LEntry(
            name: "getU8",
            descr: "Returns a unsigned 8 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true, (int index) async {
          await object!.getU8(index);
        }),
        LEntry(
            name: "get8",
            descr: "Returns a signed 8 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true, (int index) async {
          await object!.get8(index);
        }),
        LEntry(
            name: "set8",
            descr:
                "Sets a 8 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 8 bits.",
            securityCheck: writeCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to set the value at.",
              ),
              LArg<int>(
                name: "value",
                descr: "The value to set.",
              ),
            },
            isAsync: true, (int index, int value) async {
          await object!.set8(index, value);
        }),
        LEntry(
            name: "getU16",
            descr: "Returns a unsigned 16 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: int,
            isAsync: true, (int index, [bool? littleEndian]) async {
          return await object!.getU16(index, littleEndian: littleEndian);
        }),
        LEntry(
            name: "get16",
            descr: "Returns a signed 16 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: int,
            isAsync: true, (int index, [bool? littleEndian]) async {
          return await object!.get16(index, littleEndian: littleEndian);
        }),
        LEntry(
            name: "set16",
            descr:
                "Sets a 16 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 16 bits.",
            securityCheck: writeCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to set the value at.",
              ),
              LArg<int>(
                name: "value",
                descr: "The value to set.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            isAsync: true, (int index, int value, [bool? littleEndian]) async {
          await object!.set16(index, value, littleEndian: littleEndian);
        }),
        LEntry(
            name: "getU32",
            descr: "Returns a unsigned 32 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: int,
            isAsync: true,
            (int index, [bool? littleEndian]) async =>
                await object!.getU32(index, littleEndian: littleEndian)),
        LEntry(
            name: "get32",
            descr: "Returns a signed 32 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: int,
            isAsync: true,
            (int index, [bool? littleEndian]) async =>
                await object!.get32(index, littleEndian: littleEndian)),
        LEntry(
            name: "set32",
            descr:
                "Sets a 32 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 32 bits.",
            securityCheck: writeCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to set the value at.",
              ),
              LArg<int>(
                name: "value",
                descr: "The value to set.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            isAsync: true, (int index, int value, [bool? littleEndian]) async {
          await object!.set32(index, value, littleEndian: littleEndian);
        }),
        LEntry(
            name: "getU64",
            descr: "Returns a unsigned 64 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: int,
            isAsync: true,
            (int index, [bool? littleEndian]) async =>
                await object!.getU64(index, littleEndian: littleEndian)),
        LEntry(
            name: "get64",
            descr: "Returns a signed 64 bit value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: int,
            isAsync: true,
            (int index, [bool? littleEndian]) async =>
                object!.get64(index, littleEndian: littleEndian)),
        LEntry(
            name: "set64",
            descr:
                "Sets a 64 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 64 bits.",
            securityCheck: writeCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to set the value at.",
              ),
              LArg<int>(
                name: "value",
                descr: "The value to set.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            isAsync: true, (int index, int value, [bool? littleEndian]) async {
          await object!.set64(index, value, littleEndian: littleEndian);
        }),
        LEntry(
            name: "getF32",
            descr: "Returns a 32 bit float value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: double,
            isAsync: true, (int index, [bool? littleEndian]) async {
          return await object!.get32Float(index, littleEndian: littleEndian);
        }),
        LEntry(
            name: "getF64",
            descr: "Returns a 64 bit float value at the specified index.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the value at.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: double,
            isAsync: true, (int index, [bool? littleEndian]) async {
          return await object!.get64Float(index, littleEndian: littleEndian);
        }),
        LEntry(
            name: "setF32",
            descr: "Sets a 32 bit float value at the specified index.",
            securityCheck: writeCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to set the value at.",
              ),
              LArg<double>(
                name: "value",
                descr: "The value to set.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            isAsync: true, (int index, double value,
                [bool? littleEndian]) async {
          await object!.set32Float(index, value, littleEndian: littleEndian);
        }),
        LEntry(
            name: "setF64",
            descr: "Sets a 64 bit float value at the specified index.",
            securityCheck: writeCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to set the value at.",
              ),
              LArg<double>(
                name: "value",
                descr: "The value to set.",
              ),
              LArg<bool>(
                  name: "littleEndian",
                  descr:
                      "If true, the value will be little endian, otherwise it will be big endian.",
                  kind: ArgKind.optionalPositional)
            },
            isAsync: true, (int index, double value,
                [bool? littleEndian]) async {
          await object!.set64Float(index, value, littleEndian: littleEndian);
        }),
        LEntry(name: "defaultEndian", returnType: bool, args: {
          LArg<bool>(
              name: "littleEndian",
              descr:
                  "If true, the default endian will be little endian, otherwise it will be big endian.",
              kind: ArgKind.optionalPositional)
        }, ([bool? littleEndian]) {
          if (littleEndian != null) {
            object!.defaultEndian = littleEndian;
          }
          return object!.defaultEndian;
        }),
        LEntry(
            name: "getUtf16",
            descr: "Returns a utf-16 string at the specified index and length.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the string at.",
              ),
              LArg<int>(
                name: "length",
                descr: "The length of the string.",
              ),
              LArg<bool>(
                  name: "stopAtNull",
                  descr:
                      "Whether to stop at the first null character while getting the string.",
                  kind: ArgKind.optionalNamed),
            },
            returnType: String,
            isAsync: true, (int index, int length,
                {bool stopAtNull = false}) async {
          return await object!.getUtf16(index, length, stopAtNull: stopAtNull);
        }),
        LEntry(
            name: "getUtf8",
            descr: "Returns a utf-8 string at the specified index and length.",
            securityCheck: readCheck,
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get the string at.",
              ),
              LArg<int>(
                name: "length",
                descr: "The length of the string.",
              ),
              LArg<bool>(
                  name: "stopAtNull",
                  descr:
                      "Whether to stop at the first null character while getting the string.",
                  kind: ArgKind.optionalNamed),
            },
            returnType: String,
            isAsync: true, (int index, int length,
                {bool stopAtNull = false}) async {
          return await object!.getUtf8(index, length, stopAtNull: stopAtNull);
        }),
        LEntry(
          name: "length",
          descr: "Returns the length of the file in bytes.",
          securityCheck: readCheck,
          returnType: int,
          isAsync: true,
          () async => await object!.length,
        ),
        LEntry(
          name: "getSpan",
          descr:
              "Returns a span of bytes at the specified range, or the entire file if no end is specified.",
          securityCheck: readCheck,
          args: const {
            LArg<int>(
              name: "start",
              descr: "The start index.",
            ),
            LArg<int>(
                name: "end",
                descr: "The end index.",
                kind: ArgKind.optionalPositional),
          },
          returnType: Stream,
          isAsync: true,
          (int start, [int? end]) async {
            return await object!.getRange(start, end ?? await object!.length);
          },
        ),
        LEntry(
            name: "save",
            descr: "Saves the file to disk if path is external.",
            securityCheck: (cert, args) {
              if (object!.isExternal) {
                if (cert
                        .getPolicy<SPolicyExterFiles>()
                        ?.writeAllowed(object!.path) ??
                    false) {
                  return true;
                }
              }
              return false;
            },
            isAsync: true,
            () async {
              await object!.save();
            }),
        LEntry(
          name: "saveAs",
          descr: "Saves the file to the specified path.",
          securityCheck: (cert, args) {
            final externalPolicy = cert.getPolicy<SPolicyExterFiles>();
            if (!object!.isExternal) {
              /// If the file is internal, check if reading is allowed.
              if (!(cert.getPolicy<SPolicyInterFiles>()?.read ?? false)) {
                return false;
              }
            } else {
              /// If the file is external, check if reading is allowed for the filename.
              if (!(externalPolicy?.readAllowed(object!.path) ?? false)) {
                return false;
              }
            }
            if (args.positional.length == 2) {
              if (args.positional[1]) {
                if (!(cert.getPolicy<SPolicyInterFiles>()?.write ?? false)) {
                  return false;
                }
              }
            }
            if (externalPolicy?.createAllowed(args.positional[0]) ?? false) {
              return true;
            }
            return false;
          },
          args: const {
            LArg<String>(
              name: "path",
              descr: "The path to save the file to.",
            ),
            LArg<bool>(
                name: "overwrite",
                descr: "Whether to overwrite the file if it already exists.",
                kind: ArgKind.optionalPositional),
          },
          isAsync: true,
          (String path, [bool overwrite = false]) async {
            await object!.saveAs(path, overwrite: overwrite);
          },
        ),
        LEntry(
            name: "extension",
            descr: "Returns the extension of the file.",
            returnType: String,
            () => object!.path.getExtensions()),
      };
}

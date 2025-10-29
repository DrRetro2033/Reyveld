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
  get statics => {};

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
A file either stored on disk or in an SArchive. 

Contains the path of the file, and its data in the form of compressed base64.
""";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
          name: "open",
          descr: "Opens a external file.",
          isAsync: true,
          args: const {
            LArg<String>(
              name: "path",
              descr: "The path to the file.",
            ),
          },
          returnType: SFile,
          (String path) async => await SFileCreator.open(path),
        ),
        LEntry(
          name: "create",
          descr: """Creates a new file.

If the already exists and overwrite is not true, it will throw an exception.

If the file already exists and overwrite is true, it will delete the file and create a new one 
(Must be permitted to delete the external file).
""",
          isAsync: true,
          args: const {
            LArg<String>(
              name: "path",
              descr: "The path to the file.",
            ),
            LArg<bool>(
              name: "overwrite",
              descr: "Whether to overwrite the file if it already exists.",
              kind: ArgKind.optionalNamed,
            ),
          },
          securityCheck: """---@type SPolicyFiles?
    local policy = cert.getPolicy({
        type = SPolicyFiles,
        ---@param p SPolicyFiles
        filter = function(p)
            return p.isFileAssociated(object.path())
        end
    })
    if (policy == nil) then return false end
    if (not policy.createAllowed(args.get(0), true)) then
        return "Not allowed to create '" ..
            args.get(0) .. "'."
    end
    if (named["overwrite"] == true) then
        return policy.deleteAllowed(args.get(0), true)
    end
    return true
""",
          returnType: SFile,
          (String path, {bool overwrite = false}) async {
            if (await File(path).exists()) {
              if (!overwrite) throw Exception("File already exists.");
              await File(path).delete();
            }
            await File(path).create(recursive: true);
            return await SFileCreator.open(path);
          },
        ),
        LEntry(
            name: "exists",
            descr: "Checks if the file exists.",
            returnType: bool,
            isAsync: true,
            (String path) async => await File(path).exists()),
      };

  /// The default read check for files.
  String get readCheck => """
    ---@type SPolicyFiles?
    local policy = cert.getPolicy({
        type = SPolicyFiles,
        ---@param p SPolicyFiles
        filter = function(p)
            return p.isFileAssociated(object.path())
        end
    })
    if (policy == nil) then return false end
    if (policy.readAllowed(object.path(), object.isExternal())) then return true end
    return false
""";

  /// The default write check for files.
  String get writeCheck => """
      ---@type SPolicyFiles?
    local policy = cert.getPolicy({
        type = SPolicyFiles,
        ---@param p SPolicyFiles
        filter = function(p)
            return p.isFileAssociated(object.path())
        end
    })
    if (policy == nil) then return false end
    if (policy.writeAllowed(object.path(), object.isExternal())) then return true end
    return false
""";

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
          name: "isExternal",
          descr: "Returns whether the file is external or not.",
          returnType: bool,
          () => object!.isExternal,
        ),
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
          await object!.readU8(index);
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
          await object!.read8(index);
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
          await object!.write8(index, value);
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
          return await object!.readU16(index, littleEndian: littleEndian);
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
          return await object!.read16(index, littleEndian: littleEndian);
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
          await object!.write16(index, value, littleEndian: littleEndian);
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
                await object!.readU32(index, littleEndian: littleEndian)),
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
                await object!.read32(index, littleEndian: littleEndian)),
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
          await object!.write32(index, value, littleEndian: littleEndian);
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
                await object!.readU64(index, littleEndian: littleEndian)),
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
                await object!.read64(index, littleEndian: littleEndian)),
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
          await object!.write64(index, value, littleEndian: littleEndian);
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
          return await object!.read32Float(index, littleEndian: littleEndian);
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
          return await object!.read64Float(index, littleEndian: littleEndian);
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
          await object!.write32Float(index, value, littleEndian: littleEndian);
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
          await object!.write64Float(index, value, littleEndian: littleEndian);
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
          return await object!.readUtf16(index, length, stopAtNull: stopAtNull);
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
          return await object!.readUtf8(index, length, stopAtNull: stopAtNull);
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
            name: "write",
            descr: "Writes a string to the file.",
            args: const {
              LArg<String>(name: "value", descr: "The string to write.")
            },
            securityCheck: writeCheck,
            isAsync: true, (String value) async {
          await object!.write(value);
        }),
        LEntry(
            name: "writeln",
            descr: "Writes a line to the file.",
            args: const {
              LArg<String>(name: "value", descr: "The string to write.")
            },
            securityCheck: writeCheck,
            isAsync: true, (String value) async {
          await object!.writeln(value);
        }),
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
                name: "to",
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
            securityCheck: """---@type SPolicyFiles?
    local policy = cert.getPolicy({
        type = SPolicyFiles,
        ---@param p SPolicyFiles
        filter = function(p)
            return p.isFileAssociated(object.path())
        end
    })
    if (policy == nil) then return false end
    if (policy.writeAllowed(object.path(), object.isExternal())) then return true end
    return false""",
            isAsync: true, () async {
          await object!.save();
        }),
        LEntry(
          name: "saveAs",
          descr: "Saves the file to the specified path.",
          securityCheck: """
    ---@type SPolicyFiles?
    local policy = cert.getPolicy({
        type = SPolicyFiles,
        ---@param p SPolicyFiles
        filter = function(p)
            return p.isFileAssociated(object.path())
        end
    })
    if (policy == nil) then return false end
    if (args.length() == 2) then
        if (args.get(1)) then
            if (not policy.writeAllowed(args.get(0), true)) then return false end
        end
    end
    if (policy.createAllowed(args.get(0), true)) then return true end
    return false""",
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
            name: "discard",
            descr: "Discards any unsaved changes.",
            isAsync: true,
            () async => await object!.discard()),
        LEntry(
            name: "extension",
            descr: "Returns the extension of the file.",
            returnType: String,
            () => object!.path.getExtensions()),
      };
}

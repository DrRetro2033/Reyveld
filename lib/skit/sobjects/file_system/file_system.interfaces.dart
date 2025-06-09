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
            (state) => object!.getFiles().map<String>((e) => e!.path).toList()),
        LEntry(
            name: "files",
            descr: "Returns the files in the archive",
            returnType: List,
            (state) => object!.getFiles()),
        LEntry(
            name: "getFile",
            descr: "Returns the file with the path provided",
            args: {
              "path": LArg<String>(
                descr: "The path of the file",
              )
            },
            returnType: SFile,
            (String name) async => object!.getFile(name)),
        LEntry(
            name: "extract",
            descr: "Extracts the archive to the specified path",
            args: const {
              "path": LArg<String>(
                descr: "The path to extract the archive to",
              ),
            },
            isAsync: true,
            (String path) async => await object!.extract(path).listen((state) {
                  Arceus.talker.info("Extracted file: $state");
                }).asFuture()),
      };
}

final class SFileInterface extends SInterface<SFile> {
  @override
  get className => "SFile";

  @override
  get classDescription => """
A file in a SArchive. Contains the path of the file, and its data in the form of compressed base64.
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
              "path": LArg<String>(
                descr: "The path to open the file at.",
              )
            },
            isAsync: true, (path) async {
          return await SFileCreator.open(path);
        }),
      };

  @override
  get exports => {
        LEntry(
            name: "extract",
            descr: "Extracts the file to the specified path",
            args: const {
              "path": LArg<String>(
                descr: "The path to extract the file to.",
              ),
            },
            isAsync: true,
            (state) async =>
                object!.extractTo(await state.getFromTop<String>())),
        LEntry(
            name: "path",
            descr: "Returns the path of the file",
            returnType: String,
            (state) => object!.path),
        LEntry(
            name: "getU8",
            descr: "Returns a unsigned 8 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.getU8(index)),
        LEntry(
            name: "get8",
            descr: "Returns a signed 8 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.get8(index)),
        LEntry(
            name: "set8",
            descr:
                "Sets a 8 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 8 bits.",
            args: const {
              "index": LArg<int>(
                descr: "The index to set the value at.",
              ),
              "value": LArg<int>(
                descr: "The value to set.",
              ),
            },
            isAsync: true, (int index, int value) async {
          await object!.set8(index, value);
        }),
        LEntry(
            name: "getU16",
            descr: "Returns a unsigned 16 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.getU16(index)),
        LEntry(
            name: "get16",
            descr: "Returns a signed 16 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.get16(index)),
        LEntry(
            name: "set16",
            descr:
                "Sets a 16 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 16 bits.",
            args: const {
              "index": LArg<int>(
                descr: "The index to set the value at.",
              ),
              "value": LArg<int>(
                descr: "The value to set.",
              ),
            },
            isAsync: true, (int index, int value) async {
          await object!.set16(index, value);
        }),
        LEntry(
            name: "getU32",
            descr: "Returns a unsigned 32 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.getU32(index)),
        LEntry(
            name: "get32",
            descr: "Returns a signed 32 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.get32(index)),
        LEntry(
            name: "set32",
            descr:
                "Sets a 32 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 32 bits.",
            args: const {
              "index": LArg<int>(
                descr: "The index to set the value at.",
              ),
              "value": LArg<int>(
                descr: "The value to set.",
              ),
            },
            isAsync: true, (int index, int value) async {
          await object!.set32(index, value);
        }),
        LEntry(
            name: "getU64",
            descr: "Returns a unsigned 64 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.getU64(index)),
        LEntry(
            name: "get64",
            descr: "Returns a signed 64 bit value at the specified index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the value at.",
              ),
            },
            returnType: int,
            isAsync: true,
            (int index) async => object!.get64(index)),
        LEntry(
            name: "set64",
            descr:
                "Sets a 64 bit value at the specified index. It does not matter if the value is signed or unsigned, only that it fits into 64 bits.",
            args: const {
              "index": LArg<int>(
                descr: "The index to set the value at.",
              ),
              "value": LArg<int>(
                descr: "The value to set.",
              ),
            },
            isAsync: true, (int index, int value) async {
          await object!.set64(index, value);
        }),
        LEntry(
            name: "getS16",
            descr: "Returns a string at the specified index and length.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get the string at.",
              ),
              "length": LArg<int>(
                descr: "The length of the string.",
              ),
              "stopAtNull": LArg<bool>(
                  descr:
                      "Whether to stop at the first null character while getting the string.",
                  required: false),
            },
            returnType: String,
            isAsync: true, (int index, int length,
                [bool stopAtNull = false]) async {
          return await object!.getStr16(index, length, stopAtNull: stopAtNull);
        }),
        LEntry(
            name: "save",
            descr: "Saves the file to disk if path is external.",
            isAsync: true, () async {
          await object!.save();
        }),
        LEntry(
          name: "saveAs",
          descr: "Saves the file to the specified path.",
          args: const {
            "path": LArg<String>(
              descr: "The path to save the file to.",
            ),
            "overwrite": LArg<bool>(
                descr: "Whether to overwrite the file if it already exists.",
                required: false),
          },
          isAsync: true,
          (String path, [bool overwrite = false]) async {
            await object!.saveAs(path, overwrite: overwrite);
          },
        )
      };
}

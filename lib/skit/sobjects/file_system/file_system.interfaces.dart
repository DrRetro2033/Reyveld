part of 'file_system.dart';

class SArchiveInterface extends SInterface<SArchive> {
  @override
  get className => "SArchive";

  @override
  get classDescription => """
An archive in a SKit. Contains files.
""";

  @override
  get parent => SObjectInterface();

  @override
  get exports => {
        "filepaths": (
          "Returns the filepaths of the files in the archive",
          {},
          List,
          (state) => object!.getFiles().map<String>((e) => e!.path).toList()
        ),
        "files": (
          "Returns the files in the archive",
          {},
          List,
          (state) => object!.getFiles()
        ),
        "getFile": (
          "Returns the file with the path provided",
          {"path": ("The path of the file", type: String, isRequired: true)},
          SFile,
          (state) async => object!.getFile(await state.getFromTop<String>())
        ),
        "extract": (
          "Extracts the archive to the specified path",
          {
            "path": (
              "The path to extract the archive to",
              type: String,
              isRequired: true
            ),
          },
          null,
          (state) async => object!.extract(await state.getFromTop<String>())
        ),
      };
}

class SFileInterface extends SInterface<SFile> {
  @override
  get className => "SFile";

  @override
  get classDescription => """
A file in a SArchive. Contains the path of the file, and its data in the form of compressed base64.
""";

  @override
  get parent => SObjectInterface();

  @override
  get exports => {
        "extract": (
          "Extracts the file to the specified path",
          {
            "path": (
              "The path to extract the file to.",
              type: String,
              isRequired: true
            ),
          },
          null,
          (state) async => object!.extract(await state.getFromTop<String>())
        ),
        "path": (
          "Returns the path of the file",
          {},
          String,
          (state) => object!.path
        ),
        "getU8": (
          "Returns a unsigned 8 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.getU8(index)
        ),
        "get8": (
          "Returns a signed 8 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.get8(index)
        ),
        "getU16": (
          "Returns a unsigned 16 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.getU16(index)
        ),
        "get16": (
          "Returns a signed 16 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.get16(index)
        ),
        "getU32": (
          "Returns a unsigned 32 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.getU32(index)
        ),
        "get32": (
          "Returns a signed 32 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.get32(index)
        ),
        "getU64": (
          "Returns a unsigned 64 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.getU64(index)
        ),
        "get64": (
          "Returns a signed 64 bit value at the specified index.",
          {
            "index": (
              "The index to get the value at.",
              type: int,
              isRequired: true
            ),
          },
          int,
          (int index) async => object!.get64(index)
        ),
        "getS16": (
          "Returns a string at the specified index and length.",
          {
            "index": (
              "The index to get the string at.",
              type: int,
              isRequired: true
            ),
            "length": (
              "The length of the string.",
              type: int,
              isRequired: true
            ),
            "stopAtNull": (
              "Whether to stop at the first null character while getting the string.",
              type: bool,
              isRequired: false
            ),
          },
          String,
          (int index, int length, [bool stopAtNull = false]) async {
            return await object!
                .getStr16(index, length, stopAtNull: stopAtNull);
          }
        ),
      };
}

class SRFileInterface extends SFileInterface {}

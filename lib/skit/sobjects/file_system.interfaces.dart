part of 'file_system.dart';

class SArchiveInterface extends SObjectInterface<SArchive> {
  @override
  get className => "SArchive";

  @override
  get description => """
An archive in a SKit. Contains files.
""";

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
          {"path": ("The path of the file", String, true)},
          SFile,
          (state) async => object!.getFile(await state.getFromTop<String>())
        ),
        "extract": (
          "Extracts the archive to the specified path",
          {
            "path": ("The path to extract the archive to", String, true),
          },
          null,
          (state) async => object!.extract(await state.getFromTop<String>())
        ),
      };
}

class SFileInterface extends SObjectInterface<SFile> {
  @override
  get className => "SFile";

  @override
  get description => """
A file in a SArchive. Contains the path of the file, and its data in the form of compressed base64.
""";

  @override
  get exports => {
        "extract": (
          "Extracts the file to the specified path",
          {
            "path": ("The path to extract the file to.", String, true),
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
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.getU8(await state.getFromTop<int>())
        ),
        "get8": (
          "Returns a signed 8 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.get8(await state.getFromTop<int>())
        ),
        "getU16": (
          "Returns a unsigned 16 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.getU16(await state.getFromTop<int>())
        ),
        "get16": (
          "Returns a signed 16 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.get16(await state.getFromTop<int>())
        ),
        "getU32": (
          "Returns a unsigned 32 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.getU32(await state.getFromTop<int>())
        ),
        "get32": (
          "Returns a signed 32 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.get32(await state.getFromTop<int>())
        ),
        "getU64": (
          "Returns a unsigned 64 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.getU64(await state.getFromTop<int>())
        ),
        "get64": (
          "Returns a signed 64 bit value at the specified index.",
          {
            "index": ("The index to get the value at.", int, true),
          },
          int,
          (state) async => object!.get64(await state.getFromTop<int>())
        ),
      };
}

class SRFileInterface extends SFileInterface {}

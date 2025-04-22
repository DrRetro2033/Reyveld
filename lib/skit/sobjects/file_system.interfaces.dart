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
        "filepaths": (state) =>
            object!.getFiles().map<String>((e) => e!.path).toList(),
        "files": (state) => object!.getFiles(),
        "getFile": (state) async =>
            object!.getFile(await state.getFromTop<String>()),
        "extract": (state) async =>
            object!.extract(await state.getFromTop<String>()),
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
        "extract": (state) async =>
            object!.extract(await state.getFromTop<String>()),
        "path": (state) => object!.path,
        "getU8": (state) async => object!.getU8(await state.getFromTop<int>()),
        "get8": (state) async => object!.get8(await state.getFromTop<int>()),
        "getU16": (state) async =>
            object!.getU16(await state.getFromTop<int>()),
        "get16": (state) async => object!.get16(await state.getFromTop<int>()),
        "getU32": (state) async =>
            object!.getU32(await state.getFromTop<int>()),
        "get32": (state) async => object!.get32(await state.getFromTop<int>()),
        "getU64": (state) async =>
            object!.getU64(await state.getFromTop<int>()),
        "get64": (state) async => object!.get64(await state.getFromTop<int>()),
      };
}

class SRFileInterface extends SFileInterface {}

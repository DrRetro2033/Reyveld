import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/sobject.dart';

part 'file_system.g.dart';
part 'file_system.creators.dart';

@SGen("archive")
class SArchive extends SRoot {
  SArchive(super._kit, super._node);

  /// Returns the date the archive was archived/created on.
  DateTime get archivedOn => DateTime.parse(get("date")!);

  /// Adds a [SFile] to the archive.
  void addSFile(SFile file) => addChild(file);

  /// Adds a file to the archive.
  /// [filepath] should be relative to the archive. For instance: "C://path/to/folder/example.txt" will translate to "example.txt".
  Future<void> addFile(String filepath, Stream<List<int>> data) async {
    final file = await SFileCreator(filepath, data).create(kit);
    addSFile(file);
  }

  /// Returns a [SFile] from the archive.
  /// [filepath] should be relative to the archive. For instance: "C://path/to/folder/example.txt" will translate to "example.txt".
  SFile? getFile(String path) {
    return getChild<SFile>(filter: (e) => e.path == path);
  }

  /// Returns a list of all of the files in the archive.
  List<SFile?> getFiles() => getChildren<SFile>();

  /// Checks for changes between the archive and the path provided.
  Future<bool> checkForChanges(String path) async {
    final files = getFiles();
    final extFiles = Directory(path).list(recursive: true);
    final addedFiles = await extFiles.any((file) {
      // file was added
      if (file is File) {
        final filePath = file.path.relativeTo(path);
        if (filePath.endsWith(".tmp")) {
          return false;
        }
        final archiveFile = getFile(filePath);
        if (archiveFile == null) {
          // does the archive not have this file?
          return true;
        }
      }
      return false;
    });
    if (addedFiles) return true;
    for (final file in files) {
      final filePath = "$path/${file!.path}";
      final extFile = File(filePath);
      // does the external version of the file exist?
      if (!await extFile.exists()) {
        return true; // file was deleted
      }
      final extFileRandomAccess = await extFile.open();
      final extLength = await extFileRandomAccess.length();
      final length = await file.length;
      if (length != extLength) {
        Arceus.talker.warning(
            "Miss matched file length to external: $length ~ $extLength");
        return true;
      }
      if (await file.length == 0) {
        continue;
      }
      await extFileRandomAccess.setPosition(0);
      await for (List<int> chunk in file.bytes) {
        if (await extFileRandomAccess.position() + chunk.length >=
            await extFileRandomAccess.length()) {
          break;
        }
        final extChunk = await extFileRandomAccess.read(chunk.length);
        if (!chunk.equals(extChunk)) {
          Arceus.talker.warning("Miss matched chunks: $chunk ~ $extChunk");
          return true;
        }
      }
    }
    return false;
  }

  /// Extracts the archive to the specified path.
  /// If [temp] is true, then the files will be extracted as temporary files with a `.tmp` extension.
  /// Returns a stream that emits the path of the file currently being extracted.
  Stream<String> extract(String path, {bool temp = false}) async* {
    final files = getFiles();
    for (final file in files) {
      yield file!.path;
      await file.extract(path, temp: temp);
    }
  }
}

extension SArchiveExtensions on SKit {
  /// Returns an archive from the kit file with the specified hash.
  Future<SArchive?> getArchive(String hash) async {
    return await getRoot<SArchive>(filterRoots: (e) => e.hash == hash);
  }
}

/// A file in an [SArchive].
/// Contains the path of the file, and its data in the form of compressed base64.
@SGen("file")
class SFile extends SObject {
  SFile(super._kit, super._node);

  /// Returns the path of the file.
  String get path => get("path")!;

  /// Returns the data of the file as a list of bytes. (NOT RECOMMENDED TO USE. USE [bytes] INSTEAD)
  List<int> get bytesSync {
    return gzip.decode(base64Decode(innerText!));
  }

  /// Returns a stream of the bytes stored, uncompressing along the way.
  Stream<List<int>> get bytes =>
      Stream.fromIterable(base64Decode(innerText!).chunk(32))
          .transform(gzip.decoder);

  /// Attempts to get the length of the file. If it fails, then it will return a 0;
  Future<int> get length => bytes
      .map<int>((chunk) => chunk.length)
      .reduce((a, b) => a + b)
      .catchError((e) => 0);

  /// Returns the data of the file as a string. (will be used for scripting in the future.)
  String get textSync => utf8.decode(bytesSync);

  Future<void> extract(String folderPath, {bool temp = false}) async {
    final filePath = "$folderPath/$path${temp ? ".tmp" : ""}";
    final extFile = File(filePath);
    await extFile.create(recursive: true);
    final sink = extFile.openWrite();
    await sink.addStream(bytes);
    await sink.flush();
    await sink.close();
  }
}

/// A reference to an [SArchive].
/// Contains the hash of the archive.
@SGen("rarchive")
class SRArchive extends SReference<SArchive> {
  SRArchive(super.kit, super.node);

  String get hash => get("hash")!;

  set hash(String? hash) => set("hash", hash);

  @override
  FutureOr<SArchive?> getRef() async {
    return await kit.getArchive(hash);
  }
}

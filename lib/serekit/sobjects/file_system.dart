import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/sobject.dart';

part 'file_system.g.dart';

class SArchive extends SObject {
  static Set<String> markedForDeletion = {};

  SArchive(super._kit, super._node);

  /// Returns the hash of the archive.
  String get hash => get("hash")!;

  /// Sets the hash of the archive.
  set hash(String? hash) => set("hash", hash);

  /// Returns the date the archive was archived/created on.
  DateTime get archivedOn => DateTime.parse(get("date")!);

  /// Marks the archive for deletion.
  /// Adds the archive's hash to the [markedForDeletion] set.
  void markForDeletion() => markedForDeletion.add(hash);

  /// Adds a [SFile] to the archive.
  void addSFile(SFile file) => addChild(file);

  /// Adds a file to the archive.
  /// [filepath] should be relative to the archive. For instance: "C://path/to/folder/example.txt" will translate to "example.txt".
  Future<void> addFile(String filepath, List<int> data) async {
    final file =
        await SFileFactory().create(kit, {"path": filepath, "data": data});
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
        final archiveFile = getFile(filePath);
        if (archiveFile == null) {
          return true;
        }
      }
      return false;
    });
    if (addedFiles) return true;
    for (final file in files) {
      final filePath = "$path/${file!.path}";
      final extFile = File(filePath);
      if (!await extFile.exists()) {
        return true; // file was deleted
      }
      final extFileRandomAccess = await extFile.open();
      if (await extFileRandomAccess.length() != file.bytesSync.length) {
        return true;
      }
      for (int pos = 0; pos < await extFileRandomAccess.length(); pos++) {
        final byte = await extFileRandomAccess
            .setPosition(pos)
            .then<int>((ext) => ext.readByte());
        if (byte != file.bytesSync[pos]) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> extract(String path) async {
    final files = getFiles();
    for (final file in files) {
      final filePath = "$path/${file!.path}";
      final extFile = File(filePath);
      await extFile.create(recursive: true);
      await extFile.writeAsBytes(file.bytesSync);
    }
  }
}

/// A file in an [SArchive].
/// Contains the path of the file, and its data in the form of compressed base64.
class SFile extends SObject {
  SFile(super._kit, super._node);

  /// Returns the path of the file.
  String get path => get("path")!;

  /// Returns the data of the file as a list of bytes.
  List<int> get bytesSync {
    final encoded = innerText!;
    return gzip.decode(base64Decode(encoded));
  }

  /// Returns the data of the file as a string.
  String get textSync => utf8.decode(bytesSync);
}

/// A reference to an [SArchive].
/// Contains the hash of the archive.
class SRArchive extends SReference<SArchive> {
  SRArchive(super.kit, super.node);

  String get hash => get("hash")!;

  set hash(String? hash) => set("hash", hash);

  @override
  FutureOr<SArchive?> getRef() async {
    return kit.getArchive(hash);
  }
}

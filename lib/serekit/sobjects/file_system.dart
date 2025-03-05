import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/sobject.dart';
import 'package:rxdart/rxdart.dart';
import 'package:async/async.dart';

part 'file_system.g.dart';
part 'file_system.creators.dart';

@SGen("archive")
class SArchive extends SRoot {
  @override
  String get displayName => "Archive";

  SArchive(super._kit, super._node);

  /// Returns the date the archive was archived/created on.
  DateTime get archivedOn => DateTime.parse(get("date")!);

  /// Adds a [SFile] to the archive.
  void addSFile(SFile file) => addChild(file);

  /// Adds a file to the archive.
  /// [filepath] must be relative to the archive. For instance: "C://path/to/folder/example.txt" will translate to "example.txt".
  Future<void> addFile(String filepath, Stream<List<int>> data) async {
    final file = await SFileCreator(filepath, data).create(kit);
    addSFile(file);
  }

  /// Returns a [SFile] from the archive.
  SFile? getFile(String path) {
    return getChild<SFile>(filter: (e) => e.path == path);
  }

  /// Returns true if the archive has a file with the path provided (must be relative to the archive).
  bool hasFile(String path) => getFile(path) != null;

  /// Returns a list of all of the files in the archive.
  List<SFile?> getFiles() => getChildren<SFile>();

  /// Checks for changes between the archive and the path provided.
  /// This method uses isolates to check for changes in parallel to speed up the process.
  /// Returns true if there are changes, false if there are none.
  /// Changes that are checked include new files, deleted files, and changes in files.
  Future<bool> checkForChanges(String path) async {
    final stopwatch = Stopwatch();
    Arceus.talker.debug("Attempting to check for changes at $path");
    stopwatch.start();
    final files = getFiles();

    /// Gets the files in the archive
    final results = await Future.wait([
      Isolate.run<bool>(
          () async => await _checkForNewFiles(path)), // check for new files
      Isolate.run<bool>(() async =>
          await _checkForDeletedFiles(path)), // check for deleted files
      for (final file in files)
        Isolate.run<bool>(
            () async => await _checkForChange(file!, path)) // check for changes
    ]);
    final changes = results.any((e) => e);

    stopwatch.stop();
    if (changes) {
      Arceus.talker
          .info("Changes found in ${stopwatch.elapsedMilliseconds}ms! ($path)");
      return true;
    }
    Arceus.talker.info(
        "No changes found in ${stopwatch.elapsedMilliseconds}ms! ($path)");
    return false;
  }

  Future<bool> _checkForNewFiles(String path) async {
    final extFiles = Directory(path).list(recursive: true);
    final addedFiles = await extFiles.whereType<File>().any((file) {
      final filePath = file.path.relativeTo(path);
      if (filePath.endsWith(".tmp")) {
        return false;
      }
      final archiveFile = getFile(filePath);
      // does the archive not have this file?
      if (archiveFile == null) {
        return true; // file was added
      }
      return false;
    });
    if (addedFiles) return true;
    return false;
  }

  Future<bool> _checkForDeletedFiles(String relativePath) async {
    for (final file in getFiles()) {
      final filePath = "$relativePath/${file!.path}";
      final extFile = File(filePath);
      if (!await extFile.exists()) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _checkForChange(SFile file, String path) async {
    final filePath = "$path/${file.path}";
    final extFile = File(filePath);
    if (!await extFile.exists()) {
      return true;
    }

    final extStream = extFile.openRead();
    final diffStream = file.streamDiff(extStream);
    final diff = await diffStream.any((e) => e.any((e) => e != 0));
    if (diff) return true;
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
  @override
  String get displayName => path;
  static const chunkSize = 65536;
  SFile(super._kit, super._node);

  /// Returns the path of the file.
  String get path => get("path")!;

  /// Returns the data of the file as a list of bytes. (NOT RECOMMENDED TO USE. USE [bytes] INSTEAD)
  List<int> get bytesSync {
    return gzip.decode(base64Decode(innerText!));
  }

  /// Returns a stream of the bytes stored, uncompressing along the way.
  FutureOr<Stream<List<int>>> get bytes =>
      Stream.fromIterable(base64Decode(innerText!))
          .chunk(chunkSize)
          .transform(gzip.decoder)
          .expand((e) => e)
          .chunk(chunkSize);

  /// Attempts to get the length of the file. If it fails, then it will return a 0;
  Future<int> get length async => (await bytes)
      .map<int>((chunk) => chunk.length)
      .reduce((a, b) => a + b)
      .catchError((e) => 0);

  /// Returns the data of the file as a string. (will be used for scripting in the future.)
  String get textSync => utf8.decode(bytesSync);

  Stream<List<int>> streamDiff(Stream<List<int>> other) async* {
    var queueA = StreamQueue(await bytes);
    var queueB = StreamQueue(other);
    while (await queueA.hasNext || await queueB.hasNext) {
      List<int?> valueA =
          await ((await queueA.hasNext) ? await queueA.next : Future.value([]));
      List<int?> valueB =
          await ((await queueB.hasNext) ? await queueB.next : Future.value([]));
      int chunkSize =
          valueA.length > valueB.length ? valueA.length : valueB.length;
      List<int> diff = [];
      for (int i = 0; i < chunkSize; i++) {
        int byte1 = i < valueA.length ? valueA.elementAt(i)! : 0;
        int byte2 = i < valueB.length ? valueB.elementAt(i)! : 0;
        diff.add((byte1 - byte2) % 255);
      }
      yield diff;
    }
  }

  Future<void> extract(String folderPath, {bool temp = false}) async {
    final filePath = "$folderPath/$path${temp ? ".tmp" : ""}";
    final extFile = File(filePath);
    await extFile.create(recursive: true);
    final sink = extFile.openWrite();
    await sink.addStream(await bytes);
    await sink.flush();
    await sink.close();
  }
}

/// A reference to an [SArchive].
@SGen("rarchive")
class SRArchive extends SIndent<SArchive> {
  @override
  String get displayName => "Archive Reference";
  SRArchive(super.kit, super.node);

  @override
  Future<SArchive?> getRef() async {
    return await kit.getArchive(hash);
  }
}

@SGen("rfile")
class SRFile extends SFile {
  String get archiveHash => get("archive")!;
  String get filePath => get("path")!;

  @override
  Future<Stream<List<int>>> get bytes => kit
      .getArchive(archiveHash)
      .then((value) async => await value!.getFile(filePath)!.bytes);

  SRFile(super.kit, super.node);
}

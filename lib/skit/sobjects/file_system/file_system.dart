import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:hashlib/hashlib.dart';
import 'package:rxdart/rxdart.dart';
import 'package:async/async.dart';

part 'file_system.g.dart';
part 'file_system.creators.dart';
part 'file_system.interfaces.dart';

/// Represents an archive in a kit file.
/// An archive is a collection of internal [SFile]s.
@SGen("archive")
class SArchive extends SRoot {
  SArchive(super._node);

  /// Returns the date the archive was archived/created on.
  DateTime get archivedOn => DateTime.parse(get("date")!);

  /// Adds a file to the archive.
  /// [filepath] must be relative to the archive. For instance: "C://path/to/folder/example.txt" will translate to "example.txt".
  Future<void> addFile(String filepath, Stream<List<int>> data) async {
    final file = await SFileCreator(filepath, data).create();
    addChild(file);
  }

  @override
  void addChild(SObject child) {
    if (child is SFile) {
      if (child.isExternal) {
        throw Exception("Cannot add an external file to an archive!");
      }
      super.addChild(child);
    } else {
      throw Exception("Cannot add a ${child.runtimeType} to an archive!");
    }
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
  ///
  /// This method uses isolates to check for changes in parallel to speed up the process.
  /// Returns true if there are changes, false if there are none.
  /// This check includes new files, deleted files, and changes in files.
  Future<bool> checkForChanges(String path) async {
    final stopwatch = Stopwatch(); // track process time.
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
    await Future.wait(files.map(
        (e) => Isolate.run(() async => await e!.extractTo(path, temp: temp))));
  }

  Future<bool> isDifferent(SArchive other) async {
    final files = getFiles();
    final otherFiles = other.getFiles();
    if (getFiles().map((e) => e!.path) !=
        other.getFiles().map((e) => e!.path)) {
      return true;
    }
    for (int i = 0; i < files.length; i++) {
      final file = files[i]!;
      final otherFile = otherFiles[i]!;
      final diffStream = file.streamDiff(await otherFile.bytes);
      if (await diffStream.any((e) => e.any((e) => e != 0))) return true;
    }
    return false;
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
///
/// [isExternal] is used to determine if the file is stored on disk or in an [SArchive].
/// Some functions will only work on external files, like [save].
@SGen("file")
class SFile extends SObject {
  /// The chunk size is used to chunk the bytes properly for decompression.
  static const chunkSize = 65536;
  SFile(super._node);

  /// Returns the path of the file.
  String get path => get("path")!;

  bool get isExternal => get("extern")! == "1";

  /// Returns a stream of the bytes stored, uncompressing along the way.
  FutureOr<Stream<List<int>>> get bytes => Stream.fromIterable(
          base64Decode(innerText!))
      .chunk(chunkSize)
      .transform(gzip.decoder)
      .expand((e) =>
          e) // Rechunks the stream to make sure each chunk is sized correctly.
      .chunk(chunkSize);

  /// A single byte version of [bytes].
  Future<Stream<int>> get singleBytes async => (await bytes).expand((e) => e);

  /// Returns a string version of the data in the file.
  Future<String> get str async =>
      (await bytes).map((e) => String.fromCharCodes(e)).join();

  /// Attempts to get the length of the file. If it fails, then it will return a 0;
  Future<int> get length async => (await bytes)
      .map<int>((chunk) => chunk.length)
      .reduce((a, b) => a + b)
      .catchError((e) => 0);

  String get checkSum => get("checksum")!;

  /// Returns a stream of the difference between this file and a data stream.
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

  /// Returns a stream of the bytes at the specified range.
  Future<Stream<int>> getRange(int start, int end) async =>
      (await singleBytes).defaultIfEmpty(0).skip(start).take(end - start);

  Future<void> setRange(int start, int end, Iterable<int> data) async {
    if (data.length > end - start) {
      throw Exception(
          "Data is too large for the specified range of ${end - start} bytes! Please make sure the data is smaller than the range.");
    }
    innerText = await _setBytes(start, end, data.toList())
        .chunk(chunkSize)
        .transform(gzip.encoder)
        .expand((e) => e)
        .chunk(chunkSize)
        .transform(base64.encoder)
        .reduce((a, b) => a + b);
  }

  Stream<int> _setBytes(int start, int end, List<int> data) async* {
    int i = 0;
    await for (final byte in await singleBytes) {
      if (i >= start && i < end) {
        yield data.lastOrNull ?? 0;
        if (data.isNotEmpty) {
          data.removeLast();
        }
      } else {
        yield byte;
      }
      i++;
    }
  }

  Future<int> getU8(int index) async {
    return _formNumber(await getRange(index, index + 1));
  }

  Future<int> get8(int index) async {
    return (await getU8(index)).toSigned(8);
  }

  Future<void> set8(int index, int value) async {
    await setRange(index, index + 1, _seperateInt(value));
  }

  /// Merges two bytes into one. This is used to form numbers larger than one byte.
  int _mergeInt(a, b) => (a << 8) | b;

  Iterable<int> _seperateInt(int number) sync* {
    while (number > 0) {
      yield number & 0xFF;
      number = number >> 8;
    }
  }

  /// Forms a number from a stream of bytes.
  /// Reverses the stream before merging.
  Future<int> _formNumber(Stream<int> stream) async {
    return stream.toList().then((e) => e.reversed.reduce(_mergeInt));
  }

  Future<int> getU16(int index) async {
    return _formNumber(await getRange(index, index + 2));
  }

  Future<void> set16(int index, int value) async {
    final seperated = _seperateInt(value);
    Arceus.talker.log(seperated);
    await setRange(index, index + 2, seperated);
  }

  Future<int> get16(int index) async => (await getU16(index)).toSigned(16);

  Future<int> getU32(int index) async {
    return _formNumber(await getRange(index, index + 4));
  }

  Future<int> get32(int index) async => (await getU32(index)).toSigned(32);

  Future<void> set32(int index, int value) async {
    await setRange(index, index + 4, _seperateInt(value));
  }

  Future<int> getU64(int index) async {
    return _formNumber(await getRange(index, index + 8));
  }

  Future<int> get64(int index) async => (await getU64(index)).toSigned(64);

  Future<void> set64(int index, int value) async {
    await setRange(index, index + 8, _seperateInt(value));
  }

  Future<String> getStr16(int index, int length,
      {bool stopAtNull = false}) async {
    final bytes = await getRange(index, index + (length * 2));
    final buffer = StringBuffer();
    await for (final char in bytes.chunk(2)) {
      if (stopAtNull && char[0] == 0 && char[1] == 0) break;
      buffer.writeCharCode(_mergeInt(char[1], char[0]));
    }
    return buffer.toString();
  }

  /// Extracts the file to the specified folder.
  /// If [temp] is true, then the file will be extracted as a temporary file with a `.tmp` extension.
  Future<void> extractTo(String folderPath, {bool temp = false}) async {
    final filePath = "$folderPath/$path${temp ? ".tmp" : ""}";
    final extFile = File(filePath);
    await extFile.create(recursive: true);
    final sink = extFile.openWrite();
    await sink.addStream(await bytes);
    await sink.flush();
    await sink.close();
  }

  /// Saves the file its path defined by [path].
  Future<void> save() async {
    if (!isExternal) throw Exception("Cannot save an internal file!");
    final file = File(path);
    if (!file.isAbsolute) {
      throw Exception(
          "File path is not absolute! To save a SFile onto disk using save(), its path must be absolute. See saveAs() instead.");
    }
    await file.create(recursive: true);
    final sink = file.openWrite();
    await sink.addStream(await bytes);
    await sink.flush();
    await sink.close();
  }

  /// Saves the file to the specified path.
  Future<void> saveAs(String path, {bool overwrite = false}) async {
    final file = File(path);
    if (overwrite && await file.exists()) await file.delete();
    await file.create(recursive: true, exclusive: true);
    final sink = file.openWrite();
    await sink.addStream(await bytes);
    await sink.flush();
    await sink.close();
  }
}

/// A reference to an [SArchive].
@SGen("rarchive")
class SRArchive extends SIndent<SArchive> {
  SRArchive(super.node);

  @override
  Future<SArchive?> getRef() async {
    return await kit.getArchive(hash);
  }
}

/// A reference to an [SFile] in a [SArchive].
@SGen("rfile")
class SRFile extends SFile {
  String get archiveHash => get("archive")!;
  String get filePath => get("path")!;

  @override
  Future<Stream<List<int>>> get bytes => kit
      .getArchive(archiveHash)
      .then((value) async => await value!.getFile(filePath)!.bytes);

  SRFile(super.node);
}

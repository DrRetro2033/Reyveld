import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:reyveld/extensions.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/security/certificate/certificate.dart';
import 'package:reyveld/security/policies/files/files.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:reyveld/skit/sobjects/file_system/filelist/filelist.dart';
import 'package:rxdart/rxdart.dart';

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
  Future<bool> checkForChanges(String path, {Globs? includeList}) async {
    final stopwatch = Stopwatch(); // track process time.    stopwatch.start();
    final files = getFiles();

    /// Gets the files in the archive
    final results = await Future.wait([
      Isolate.run<bool>(() async => await _checkForNewFiles(path,
          includeList: includeList)), // check for new files
      Isolate.run<bool>(() async =>
          await _checkForDeletedFiles(path)), // check for deleted files
      for (final file in files)
        Isolate.run<bool>(() async =>
            await _checkForChangedFiles(file!, path)) // check for changes
    ]);
    final changes = results.any((e) => e);

    stopwatch.stop();
    return changes;
  }

  /// Checks for new files, by comparing the files in the archive with the files in the path provided.
  /// Returns true if there are new files, false if there are none.
  Future<bool> _checkForNewFiles(String path, {Globs? includeList}) async {
    final extFiles = Directory(path).list(recursive: true);
    final addedFiles = await extFiles.whereType<File>().any((file) {
      final filePath = file.path.relativeTo(path);
      if (filePath.endsWith(".tmp")) {
        return false;
      }
      if (includeList != null && !includeList.included(filePath)) return false;
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

  /// Checks for deleted files, by comparing the files in the archive with the files in the path provided.
  /// Returns true if there are deleted files, false if there are none.
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

  /// Checks for changes in a file by comparing the checksum of the file in the archive with the file on disk.
  /// Returns true if the file has changed, false if it has not.
  Future<bool> _checkForChangedFiles(SFile file, String path) async {
    final filePath = "$path/${file.path}";
    final extFile = File(filePath);
    if (!await extFile.exists()) {
      return true;
    }

    final externChecksum = await extFile.checksum;
    if (file.checksum != externChecksum) return true;
    return false;
  }

  /// Extracts the archive to the specified path.
  /// If [temp] is true, then the files will be extracted as temporary files with a `.tmp` extension.
  /// Returns a stream that emits the path of the file currently being extracted.
  Stream<String> extract(String path, {bool temp = false}) {
    final files = getFiles();
    return Stream.fromFutures(
        files.map<Future<String>>((e) async => await Isolate.run(() async {
              await e!.extractTo(path, temp: temp);
              return e.path;
            })));
  }

  @override
  Future<SRArchive> newIndent() async => await SRArchiveCreator(hash).create();
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

  @override
  onSave(kit) async {
    if (cdata == null || checksum != await file.then((e) => e.checksum)) {
      clearInnerText();
      await refreshData();
    }
  }

  /// Returns the path of the file.
  String get path => get("path")!;

  bool get isExternal => (get("extern") ?? "0") == "1";

  /// This is the default endianness of the file.
  /// Can be set to false to force big endian as the default.
  bool defaultEndian = true;

  File? externalVersion;

  Future<File> get file async {
    externalVersion ??=
        await Reyveld.findTempFile(checksum) ?? await Reyveld.newTempFile();
    if (!await externalVersion!.exists()) {
      await externalVersion!.create(recursive: true);
      final write = externalVersion!.openWrite();
      await write.addStream(Stream.fromIterable(cdata!.chunk(chunkSize))
          .transform(gzip.decoder)
          .rechunk(chunkSize));
      await write.flush();
      await write.close();
    }

    return externalVersion!;
  }

  Future<RandomAccessFile> get ra async =>
      await file.then((e) => e.open(mode: FileMode.append));

  Future<int> get length async => await file.then((e) => e.length());

  /// Returns the checksum of the file.
  String get checksum => get("checksum")!;

  /// Returns a stream of the bytes at the specified range.
  Future<List<int>> getRange(int start, int end) async {
    return await Reyveld.withReadAndWritePool(() async => await ra
        .then((e) => e.setPosition(start))
        .then((e) => e.read(end - start)));
  }

  Future<void> setRange(
      int start, int end, Iterable<int> data, bool? littleEndian) async {
    if (data.length > end - start) {
      throw Exception(
          "Data is too large for the specified range of ${end - start} bytes! Please make sure the data is smaller than the range.");
    }
    if (!(littleEndian ?? defaultEndian)) data = data.toList().reversed;
    await Reyveld.withReadAndWritePool(() async {
      await ra
          .then((e) => e.setPosition(start))
          .then((e) => e.writeFrom(data.toList()))
          .then((e) => e.flush())
          .then((e) => e.close());
    });
  }

  Future<void> refreshData() async =>
      await Reyveld.readAndWritePool.then((e) async => cdata = await file
          .then((e) => e
              .openRead()
              .rechunk(chunkSize)
              .transform(gzip.encoder)
              .rechunk(chunkSize))
          .then((e) => e.expand((e) => e).toList()));

  Future<int> getU8(int index) async =>
      await _formNumber(await getRange(index, index + 1), false);

  Future<int> get8(int index) async => (await getU8(index)).toSigned(8);

  Future<void> set8(int index, int value) async =>
      await setRange(index, index + 1, _seperateInt(value), true);

  /// Merges two bytes into one. This is used to form numbers larger than one byte.
  int _mergeInt(a, b) => (a << 8) | b;

  Iterable<int> _seperateInt(int number) sync* {
    while (number > 0) {
      yield number & 0xFF;
      number = number >> 8;
    }
  }

  /// Forms a number from a stream of bytes.
  /// If littleEndian is true, then the stream will be reversed before merging.
  Future<int> _formNumber(List<int> data, bool? littleEndian) async {
    if (!(littleEndian ?? defaultEndian)) {
      return data.isEmpty ? 0 : data.reduce(_mergeInt);
    }
    return data.isEmpty ? 0 : data.reversed.reduce(_mergeInt);
  }

  /// Forms a unsigned number from a stream of bytes.
  Future<int> getU16(int index, {bool? littleEndian}) async =>
      await _formNumber(await getRange(index, index + 2), littleEndian);

  /// Forms a signed number from a stream of bytes.
  Future<int> get16(int index, {bool? littleEndian}) async =>
      (await getU16(index, littleEndian: littleEndian)).toSigned(16);

  /// Sets a 16 bit number at the specified index.
  Future<void> set16(int index, int value, {bool? littleEndian}) async =>
      await setRange(index, index + 2, _seperateInt(value), littleEndian);

  /// Forms a unsigned number from a stream of bytes.
  Future<int> getU32(int index, {bool? littleEndian}) async =>
      await _formNumber(await getRange(index, index + 4), littleEndian);

  /// Forms a signed number from a stream of bytes.
  Future<int> get32(int index, {bool? littleEndian}) async =>
      (await getU32(index, littleEndian: littleEndian)).toSigned(32);

  /// Sets a 32 bit number at the specified index.
  Future<void> set32(int index, int value, {bool? littleEndian}) async =>
      await setRange(index, index + 4, _seperateInt(value), littleEndian);

  /// Forms a unsigned number from a stream of bytes.
  Future<int> getU64(int index, {bool? littleEndian}) async =>
      await _formNumber(await getRange(index, index + 8), littleEndian);

  /// Forms a signed number from a stream of bytes.
  Future<int> get64(int index, {bool? littleEndian}) async =>
      (await getU64(index, littleEndian: littleEndian)).toSigned(64);

  /// Sets a 64 bit number at the specified index.
  Future<void> set64(int index, int value, {bool? littleEndian}) async =>
      await setRange(index, index + 8, _seperateInt(value), littleEndian);

  /// Forms a float from a U32.
  Future<double> get32Float(int index, {bool? littleEndian}) async {
    final getUnsigned = await getU32(index, littleEndian: littleEndian);
    final buffer = ByteData(4);
    buffer.setUint32(0, getUnsigned);
    return buffer.getFloat32(0);
  }

  Future<void> set32Float(int index, double value, {bool? littleEndian}) async {
    final buffer = ByteData(4);
    buffer.setFloat32(0, value);
    final bytes = buffer.buffer.asUint8List();
    await setRange(index, index + 4, bytes, littleEndian);
  }

  /// Forms a float from a U64.
  Future<double> get64Float(int index, {bool? littleEndian}) async {
    final getUnsigned = await getU64(index, littleEndian: littleEndian);
    final buffer = ByteData(8);
    buffer.setUint64(0, getUnsigned);
    return buffer.getFloat64(0);
  }

  Future<void> set64Float(int index, double value, {bool? littleEndian}) async {
    final buffer = ByteData(8);
    buffer.setFloat64(0, value);
    final bytes = buffer.buffer.asUint8List();
    await setRange(index, index + 8, bytes, littleEndian);
  }

  Future<String> getUtf16(int index, int length,
      {bool stopAtNull = false}) async {
    final bytes = await getRange(index, index + (length * 2));
    final buffer = StringBuffer();
    for (final char in bytes.chunk(2)) {
      if (stopAtNull && char[0] == 0 && char[1] == 0) break;
      buffer.writeCharCode(_mergeInt(char[1], char[0]));
    }
    return buffer.toString();
  }

  Future<String> getUtf8(int index, int length,
      {bool stopAtNull = false}) async {
    final bytes = await getRange(index, index + length);
    final buffer = StringBuffer();
    for (final char in bytes) {
      if (stopAtNull && char == 0) break;
      buffer.writeCharCode(char);
    }
    return buffer.toString();
  }

  /// Extracts the file to the specified folder.
  /// If [temp] is true, then the file will be extracted as a temporary file with a `.tmp` extension.
  Future<void> extractTo(String folderPath, {bool temp = false}) async {
    if (!await kit.isVerifiedAndTrusted()) {
      throw TrustException(kit, await kit.kitPublicKey);
    }
    final filePath = "$folderPath/$path${temp ? ".tmp" : ""}";
    final extFile = File(filePath);

    await extFile.create(recursive: true);
    final sink = extFile.openWrite();
    await sink.addStream((await file).openRead());
    await sink.flush();
    await sink.close();
  }

  /// Saves the file its path defined by [path].
  Future<void> save() async {
    if (!await kit.isVerifiedAndTrusted()) {
      throw TrustException(kit, await kit.kitPublicKey);
    }
    if (!isExternal) throw Exception("Cannot save an internal file!");
    final fileTo = File(path);
    if (!fileTo.isAbsolute) {
      throw Exception(
          "File path is not absolute! To save a SFile onto disk using save(), its path must be absolute. See saveAs() instead.");
    }
    await fileTo.create(recursive: true);
    final sink = fileTo.openWrite();
    await sink.addStream((await file).openRead());
    await sink.flush();
    await sink.close();
  }

  /// Saves the file to the specified path.
  Future<void> saveAs(String path, {bool overwrite = false}) async {
    if (!await kit.isVerifiedAndTrusted()) {
      throw TrustException(kit, await kit.kitPublicKey);
    }
    final fileAs = File(path);
    if (overwrite && await fileAs.exists()) await fileAs.delete();
    await fileAs.create(recursive: true, exclusive: true);
    final sink = fileAs.openWrite();
    await sink.addStream((await file).openRead());
    await sink.flush();
    await sink.close();
  }

  Future<SRFile> getRef() async {
    return await SRFileCreator(getParent<SArchive>()!.hash, path, checksum)
        .create()
      ..kit = kit;
  }
}

/// A reference to an [SArchive].
@SGen("rarchive")
class SRArchive extends SIndent<SArchive> {
  @override
  onSave(kit) async {
    if (kit.isMarkedForDeletion(hash)) {
      unparent();
    }
  }

  SRArchive(super._node);

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
  onSave(kit) async {
    if (kit.isMarkedForDeletion(archiveHash)) {
      unparent();
    }
  }

  @override
  Future<File> get file async => await kit
      .getArchive(archiveHash)
      .then((value) async => value!.getFile(filePath)!.file);

  SRFile(super._node);
  @override
  Future<SRFile> getRef() async {
    return copy();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:reyveld/extensions.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:reyveld/skit/sobjects/file_system/filelist/filelist.dart';
import 'package:rxdart/rxdart.dart';

part 'file_system.g.dart';
part 'file_system.creators.dart';
part 'file_system.interfaces.dart';

/// Represents an archive in a kit file.
/// An archive is a collection of internal [SFile]s.
@SGen("archive")
@LuaClass("""An archive in a kit file.

It is a collection of internal [SFile](lua://SFile)s.""")
class SArchive extends SRoot {
  SArchive(super._node);

  @override
  childAllowed(object) {
    if (object is SFile || object is SRFile) {
      return (true, "");
    }
    return (false, "Cannot add a ${object.runtimeType} to an $runtimeType!");
  }

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
  Future<SRArchive> newIndent() async => SRArchiveCreator(id).create();
}

extension SArchiveExtensions on SKit {
  /// Returns an archive from the kit file with the specified hash.
  Future<SArchive?> getArchive(String hash) async {
    return await getRoot<SArchive>(filterRoots: (e) => e.id == hash);
  }
}

/// A file in an [SArchive].
/// Contains the path of the file, and its data in the form of compressed base64.
///
/// [isExternal] is used to determine if the file is stored on disk or in an [SArchive].
/// Some functions will only work on external files, like [save].
@SGen("file")
@LuaClass(
    "A handler for interfacing with files, either internally (meaning from inside of an [SArchive](lua://SArchive)) or externally (meaning on disk).")
class SFile extends SObject {
  /// The chunk size is used to chunk the bytes properly for decompression.
  static const chunkSize = 65536;
  SFile(super._node);

  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;

  @override
  onSave(kit) async {
    if (cdata == null || checksum != await tempFile.then((e) => e.checksum)) {
      clearInnerText();
      await save();
    }
  }

  /// The default read check for files.
  static const String readCheck = """
    if (object.isExternal()) then
        if (cert.hasPolicy(SPolicyExterFiles)) then
            local policy = cert.getPolicyByType(SPolicyExterFiles)
            if (policy.readAllowed(object.path())) then return true else return "Not allowed to read '" .. object.filename() .. "'." end
        end
        return "No policy for external files."
    else
        if (cert.hasPolicy(SPolicyInterFiles)) then
            if (cert.getPolicyByType(SPolicyInterFiles).readAllowed()) then
                return true
            end
            return "Not allowed to read '" .. object.filename() .. "'." 
        end
        return "No policy for internal files."
    end
""";

  /// The default write check for files.
  static const String writeCheck = """
    if (object.isExternal()) then
        if (cert.hasPolicy(SPolicyExterFiles)) then
            local policy = cert.getPolicyByType(SPolicyExterFiles)
            if (policy.writeAllowed(object.path())) then return true else return "Not allowed to write '" .. object.filename() .. "'." end
        end
        return "No policy for external files."
    else
        if (cert.hasPolicy(SPolicyInterFiles)) then
            if (cert.getPolicyByType(SPolicyInterFiles).writeAllowed()) then
                return true
            end
            return "Not allowed to write '" .. object.filename() .. "'."
        end
        return "No policy for internal files."
    end
""";

  /// Returns the path of the file.
  @LuaExport("Returns the path of the file.")
  String get path => get("path")!;

  @LuaExport("Returns true if the file is stored externally.")
  bool get isExternal => externalVersion != null;

  /// This is the default endianness of the file.
  ///
  /// Can be set to false to force big endian as the default.
  bool defaultEndian = true;

  File? externalVersion;

  File? _temp;

  /// Converts the file to an internal file.
  ///
  /// If the file is already internal, it will be returned as is.
  Future<SFile> toInternal() async {
    if (!isExternal) return this;
    final temp = await Reyveld.newTempFile(path.getFilename());
    await temp.create(recursive: true);
    final sink = temp.openWrite();
    await sink.addStream(externalVersion!.openRead());
    await sink.flush();
    await sink.close();
    return SFileCreator(path, await temp.checksum).create();
  }

  Future<File> get tempFile async {
    _temp ??= await Reyveld.findTempFile(path.getFilename(), checksum) ??
        await Reyveld.newTempFile(path.getFilename());
    if (!await _temp!.exists()) {
      await _temp!.create(recursive: true);
      final write = _temp!.openWrite();
      if (isExternal) {
        await write.addStream(externalVersion!.openRead());
      } else {
        await write.addStream(Stream.fromIterable(cdata!.chunk(chunkSize))
            .transform(gzip.decoder)
            .rechunk(chunkSize));
      }

      await write.flush();
      await write.close();
    }
    return _temp!;
  }

  Future<RandomAccessFile> get ra async =>
      await tempFile.then((e) => e.open(mode: FileMode.append));

  Future<int> get length async {
    final file = await ra;
    final length = await file.length();
    await file.close();
    return length;
  }

  /// Returns the checksum of the file.
  @override
  @LuaExport("Returns the checksum of the file.")
  String get checksum => get("checksum")!;

  /// Returns a stream of the bytes at the specified range.
  @LuaExport("Returns a stream of the bytes at the specified range.",
      securityCheck: SFile.readCheck)
  Future<List<int>> getRange(int start, int end) async {
    return await Reyveld.withReadAndWritePool(() async {
      final file = await ra;
      await file.setPosition(start);
      final data = await file.read(end - start);
      await file.close();
      return data;
    });
  }

  @LuaExport("Sets the bytes at the specified range.",
      securityCheck: SFile.writeCheck)
  Future<void> setRange(int start, int end, Iterable<int> data,
      {bool? littleEndian}) async {
    if (data.length > end - start) {
      throw Exception(
          "Data is too large for the specified range of ${end - start} bytes! Please make sure the data is smaller than the range.");
    }
    if (!(littleEndian ?? defaultEndian)) data = data.toList().reversed;
    await Reyveld.withReadAndWritePool(() async {
      await ra
          .then((e) async => await e.setPosition(start))
          .then((e) async => await e.writeFrom(data.toList()))
          .then((e) async => await e.flush())
          .then((e) async => await e.close());
    });
  }

  Future<void> _refreshData() async =>
      await Reyveld.readAndWritePool.then((e) async => cdata = await tempFile
          .then((e) => e
              .openRead()
              .rechunk(chunkSize)
              .transform(gzip.encoder)
              .rechunk(chunkSize))
          .then((e) => e.expand((e) => e).toList()));

  @LuaExport(
      "Returns the unsigned (i.e. no negative numbers) byte at the specified index.",
      securityCheck: SFile.readCheck)
  Future<int> readU8(int index) async =>
      await _formNumber(await getRange(index, index + 1), false);

  @LuaExport(
      "Returns the signed (i.e. negative numbers) byte at the specified index.",
      securityCheck: SFile.readCheck)
  Future<int> read8(int index) async => (await readU8(index)).toSigned(8);

  @LuaExport("""Writes the byte value at the specified index.
  
The value can either be signed or unsigned, it doesn't matter; 
However, make sure that the value is within the range of the byte.""",
      securityCheck: SFile.writeCheck)
  Future<void> write8(int index, int value) async =>
      await setRange(index, index + 1, _seperateInt(value), littleEndian: true);

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

  @LuaExport(
      "Returns the unsigned (i.e. no negative numbers) 16 bit number at the specified index.",
      securityCheck: SFile.readCheck)
  Future<int> readU16(int index, {bool? littleEndian}) async =>
      await _formNumber(await getRange(index, index + 2), littleEndian);

  @LuaExport(
      "Returns the signed (i.e. negative numbers) 16 bit number at the specified index.",
      securityCheck: SFile.readCheck)
  Future<int> read16(int index, {bool? littleEndian}) async =>
      (await readU16(index, littleEndian: littleEndian)).toSigned(16);

  @LuaExport(
    """Writes a 16 bit number at the specified index.
    
The value can either be signed or unsigned, it doesn't matter; 
However, make sure that the value is within the range of 16 bits.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> write16(int index, int value, {bool? littleEndian}) async =>
      await setRange(index, index + 2, _seperateInt(value),
          littleEndian: littleEndian);

  @LuaExport(
    "Returns the unsigned (i.e. no negative numbers) 32 bit number at the specified index.",
    securityCheck: SFile.readCheck,
  )
  Future<int> readU32(int index, {bool? littleEndian}) async =>
      await _formNumber(await getRange(index, index + 4), littleEndian);

  @LuaExport(
    "Returns the signed (i.e. negative numbers) 32 bit number at the specified index.",
    securityCheck: SFile.readCheck,
  )
  Future<int> read32(int index, {bool? littleEndian}) async =>
      (await readU32(index, littleEndian: littleEndian)).toSigned(32);

  @LuaExport(
    """Writes a 32 bit number at the specified index.
    
The value can either be signed or unsigned, it doesn't matter; 
However, make sure that the value is within the range of 32 bits.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> write32(int index, int value, {bool? littleEndian}) async =>
      await setRange(index, index + 4, _seperateInt(value),
          littleEndian: littleEndian);

  @LuaExport(
    "Returns the unsigned (i.e. no negative numbers) 64 bit number at the specified index.",
    securityCheck: SFile.readCheck,
  )
  Future<int> readU64(int index, {bool? littleEndian}) async =>
      await _formNumber(await getRange(index, index + 8), littleEndian);

  @LuaExport(
    "Returns the signed (i.e. negative numbers) 64 bit number at the specified index.",
    securityCheck: SFile.readCheck,
  )
  Future<int> read64(int index, {bool? littleEndian}) async =>
      (await readU64(index, littleEndian: littleEndian)).toSigned(64);

  @LuaExport(
    """Writes a 64 bit number at the specified index.
    
The value can either be signed or unsigned, it doesn't matter; 
However, make sure that the value is within the range of 64 bits.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> write64(int index, int value, {bool? littleEndian}) async =>
      await setRange(index, index + 8, _seperateInt(value),
          littleEndian: littleEndian);

  @LuaExport(
    "Returns a signed (i.e. negative numbers) 32 bit float at the specified index.",
    securityCheck: SFile.readCheck,
  )
  Future<double> read32Float(int index, {bool? littleEndian}) async {
    final getUnsigned = await readU32(index, littleEndian: littleEndian);
    final buffer = ByteData(4);
    buffer.setUint32(0, getUnsigned);
    return buffer.getFloat32(0);
  }

  @LuaExport(
    """Writes a 32 bit float at the specified index.
    
Make sure that the value is within the range of 32 bits.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> write32Float(int index, double value,
      {bool? littleEndian}) async {
    final buffer = ByteData(4);
    buffer.setFloat32(0, value);
    final bytes = buffer.buffer.asUint8List();
    await setRange(index, index + 4, bytes, littleEndian: littleEndian);
  }

  @LuaExport(
    "Returns a signed (i.e. negative numbers) 64 bit float at the specified index.",
    securityCheck: SFile.readCheck,
  )
  Future<double> read64Float(int index, {bool? littleEndian}) async {
    final getUnsigned = await readU64(index, littleEndian: littleEndian);
    final buffer = ByteData(8);
    buffer.setUint64(0, getUnsigned);
    return buffer.getFloat64(0);
  }

  @LuaExport(
    """Writes a 64 bit float at the specified index.
    
Make sure that the value is within the range of 64 bits.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> write64Float(int index, double value,
      {bool? littleEndian}) async {
    final buffer = ByteData(8);
    buffer.setFloat64(0, value);
    final bytes = buffer.buffer.asUint8List();
    await setRange(index, index + 8, bytes, littleEndian: littleEndian);
  }

  @LuaExport(
    """Returns the UTF-16 string at the specified index.

If stopAtNull is true, then the string will stop at the first null character (i.e. 0x00 in hexidecimal).""",
    securityCheck: SFile.readCheck,
  )
  Future<String> readUtf16(int index, int length,
      {bool stopAtNull = false}) async {
    final bytes = await getRange(index, index + (length * 2));
    final buffer = StringBuffer();
    for (final char in bytes.chunk(2)) {
      if (stopAtNull && char[0] == 0 && char[1] == 0) break;
      buffer.writeCharCode(_mergeInt(char[1], char[0]));
    }
    return buffer.toString();
  }

  @LuaExport(
    """Returns the UTF-8 string at the specified index.

If stopAtNull is true, then the string will stop at the first null character (i.e. 0x00 in hexidecimal).""",
    securityCheck: SFile.readCheck,
  )
  Future<String> readUtf8(int index, int length,
      {bool stopAtNull = false}) async {
    final bytes = await getRange(index, index + length);
    final buffer = StringBuffer();
    for (final char in bytes) {
      if (stopAtNull && char == 0) break;
      buffer.writeCharCode(char);
    }
    return buffer.toString();
  }

  @LuaExport(
    """Writes a UTF-8 string to the file.
    
If terminate is true, then the string will be terminated with a null character (i.e. 0x00 in hexidecimal).""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> writeUtf8(int index, String value,
      {bool terminate = false}) async {
    final bytes = utf8.encode(value);
    for (final char in bytes) {
      await write8(index, char);
      index++;
    }
    if (terminate) await write8(index, 0);
  }

  @LuaExport(
    """Writes a UTF-16 string to the file.
    
If terminate is true, then the string will be terminated with a null character (i.e. 0x00 in hexidecimal).""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> writeUtf16(int index, String value,
      {bool? littleEndian, bool terminate = false}) async {
    final bytes = value.codeUnits;
    for (final char in bytes) {
      await write16(index, char, littleEndian: littleEndian);
      index += 2;
    }
    if (terminate) await write16(index, 0, littleEndian: littleEndian);
  }

  /// Writes a string to the file.
  @LuaExport(
    """Appends a plain string to the end of the file.

If you are writing to a binary file, then you should use [writeUtf8](lua://SFile.writeUtf8) or [writeUtf16](lua://SFile.writeUtf16) instead.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> write(String value) async {
    await ra
        .then((e) async => await e.setPosition(await e.length()))
        .then((e) => e.writeString(value));
  }

  @LuaExport(
    """Appends a line to the end of the file.

If you are writing to a binary file, then you should use [writelnUtf8](lua://SFile.writelnUtf8) or [writelnUtf16](lua://SFile.writelnUtf16) instead.""",
    securityCheck: SFile.writeCheck,
  )
  Future<void> writeln(String value) async {
    await ra
        .then((e) async => await e.setPosition(await e.length()))
        .then((e) => e.writeString("$value\n"));
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
    await sink.addStream((await tempFile).openRead());
    await sink.flush();
    await sink.close();
  }

  /// Saves the all the changes of a file.
  @LuaExport("""Saves the file.

This must be done to save changes in both external, and internal files.
""", securityCheck: """if (object.isExternal()) then
        local policy = cert.getPolicyByType(SPolicyExterFiles)
        if (policy == nil) then return false end
        if (policy.writeAllowed(object.path())) then return true end
    else
        if (cert.hasPolicy(SPolicyInterFiles)) then
            return cert.getPolicyByType(SPolicyInterFiles).writeAllowed()
        end
    end
    return false""")
  Future<void> save() async {
    if (isExternal) {
      await externalVersion!.create(recursive: true);
      final sink = externalVersion!.openWrite();
      await sink.addStream((await tempFile).openRead());
      await sink.flush();
      await sink.close();
    } else {
      if (!await kit.isVerifiedAndTrusted()) {
        throw TrustException(kit, await kit.kitPublicKey);
      }
      await _refreshData();
    }
  }

  /// Saves the file to the specified path.
  @LuaExport("""Saves the file to the specified path.

If overwrite is true, then the file will be overwritten if it already exists.""",
      securityCheck: """
    if not object.isExternal() then
        if (cert.hasPolicy(SPolicyInterFiles)) then return true end
    else
        --- If the file is external check if reading is allowed for the file.
        local policy = cert.getPolicyByType(SPolicyExterFiles)
        if (policy == nil) then return false end
        if (not policy.writeAllowed(object.path())) then return false end
    end
    if (args.length() == 2) then
        if (args.get(1)) then
            if (not cert.getPolicyByType(SPolicyExterFiles).writeAllowed(args.get(0))) then return false end
        end
    end
    if (cert.getPolicyByType(SPolicyExterFiles).createAllowed(args.get(0))) then return true end
    return false""")
  Future<void> saveAs(String path, {bool overwrite = false}) async {
    if (!await kit.isVerifiedAndTrusted()) {
      throw TrustException(kit, await kit.kitPublicKey);
    }
    final fileAs = File(path);
    if (overwrite && await fileAs.exists()) await fileAs.delete();
    await fileAs.create(recursive: true, exclusive: true);
    final sink = fileAs.openWrite();
    await sink.addStream((await tempFile).openRead());
    await sink.flush();
    await sink.close();
  }

  @LuaExport("Discard all changes to the file.")
  Future<void> discard() async => await Reyveld.withReadAndWritePool(() async {
        await _temp!.delete();
        _temp = null;
      });

  Future<SRFile> getRef() async {
    return SRFileCreator(getParent<SArchive>()!.id, path, checksum).create()
      ..kit = kit;
  }
}

/// A reference to an [SArchive].
@SGen("rarchive")
class SRArchive extends SIndent<SArchive> {
  SRArchive(super._node);

  // @override
  // Future<SArchive?> getRef() async {
  //   return await kit.getArchive(id);
  // }
}

/// A reference to an [SFile] in a [SArchive].
@SGen("rfile")
class SRFile extends SFile {
  String get archiveHash => get("archive")!;
  String get filePath => get("path")!;

  @override
  Future<File> get tempFile async => await kit
      .getArchive(archiveHash)
      .then((value) async => value!.getFile(filePath)!.tempFile);

  SRFile(super._node);
  @override
  Future<SRFile> getRef() async {
    return copy();
  }
}

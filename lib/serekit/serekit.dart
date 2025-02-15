import "dart:async";
import "dart:convert";
import "dart:io";
import "package:arceus/arceus.dart";
import 'package:xml/xml_events.dart';
import "package:arceus/uuid.dart";
import 'package:rxdart/rxdart.dart';

import "package:arceus/extensions.dart";

import 'package:arceus/serekit/sobject.dart';
import 'package:arceus/serekit/sobjects/sobjects.dart';
import "package:arceus/scripting/addon.dart";
import "package:arceus/version_control/constellation.dart";
import "package:arceus/version_control/star.dart";

part 'serekit.factories.dart';

enum SKitType { unspecified, constellation, constellationPack, addon, settings }

/// Represents a compressed XML file.
/// [SKit] is an abrivation for SERE kit, which is a reference to titanfall 2.
/// [SKit]s can contain any data that Arceus would ever need. It can contain data about constellations, stars, users, settings, files, and more.
/// The two core [SObject]s that is tightly nit into [SKit]s are the [SHeader] and [SArchive].
/// The [SHeader] contains information about the kit (e.g. name, version, author, constellations, etc),
/// while the [SArchive]s can contain much larger sets of data (e.g. save data, scripts, images, etc).
///
/// Every other [SObject] is optional and can be left out.
class SKit {
  /// The path to the kit file.
  final String path;

  /// The loaded [SHeader] of the kit file.
  /// This will be null if the kit file has not been loaded yet by calling [getKitHeader].
  /// Every subsequent call to [getKitHeader] will return this.
  SHeader? _kit;

  SKit(this.path);

  /// Returns the [File] of the kit file.
  File get _file => File(path);

  /// The currently loaded [SArchive]s of the kit file.
  /// This will be empty if no archive has been got yet by calling [getArchive].
  final List<SArchive> _loadedArchives = [];

  /// Returns the stream of [_file], decompressing if possible.
  /// If decompression fails, it will fallback on the raw data of the file.
  /// Do not use directly, and use [_eventStream] instead.
  Stream<List<int>> get _byteStream => _file.openRead().transform(gzip.decoder);

  /// Returns a stream of [XmlEvent]s from the file.
  /// This is used to parse the file data and get the xml events.
  Stream<List<XmlEvent>> get _eventStream => _byteStream
      .transform<String>(utf8.decoder)
      .toXmlEvents()
      .normalizeEvents()
      .withParentEvents();

  /// Returns the [SHeader] of the kit file.
  /// This is used when loading a kit file.
  FutureOr<SHeader> getKitHeader() async {
    if (_kit == null) {
      final factory = getSFactory<SHeader>();
      final eventStream = _eventStream;
      _kit = (await eventStream
              .selectSubtreeEvents((e) => e.name == factory.tag)
              .toXmlNodes()
              .expand((e) => e)
              .map((e) => factory.load(this, e))
              .toList())
          .first;
    }
    return _kit!;
  }

  /// Creates a new kit file.
  /// If the kit file already exists, it will throw an exception unless [overwrite] is true.
  /// If [type] is unspecified, it will be set to [SKitType.unspecified].
  /// Returns a future that completes when the kit file is created and saved.
  Future<SHeader> create(
      {bool overwrite = false, SKitType type = SKitType.unspecified}) async {
    if (await _file.exists() && !overwrite) {
      throw Exception("Kit file already exists.");
    }
    discardChanges(); // clear the current kit from memory
    if (!await _file.exists()) {
      await _file.create(recursive: true);
    }
    _kit = await SHeaderCreator(type).create(this);
    return _kit!;
  }

  Future<bool> exists() => _file.exists();

  /// Returns a future set of all of the hashes used by the archives in the kit.
  /// This is used when creating a new archive.
  Future<Set<String>> getArchiveHashes() async {
    final factory = getSFactory<SArchive>();
    final eventStream = _eventStream;
    return (await eventStream
            .selectSubtreeEvents((e) => e.name == factory.tag)
            .toXmlNodes()
            .expand((e) => e)
            .map((e) => factory.load(this, e).hash)
            .toSet())
        .cast<String>();
  }

  /// Returns a future that generates an unique hash for an archive.
  /// This is used when creating a new archive.

  /// Returns a stream of [SArchive] objects.
  /// This is used when saving an already existing kit file.
  /// Does not stream loaded, or marked for deletion archives.
  Stream<SArchive> _streamUnloadedArchives() {
    final factory = getSFactory<SArchive>();
    return _eventStream
        .selectSubtreeEvents((e) {
          // Only loads unloaded and undeleted archives.
          if (e.localName != factory.tag) {
            return false;
          }
          final hash = e.attributes.firstWhere((x) => x.name == "hash").value;
          if (SArchive.markedForDeletion.contains(hash) ||
              _loadedArchives.any((y) => y.hash == hash)) {
            return false;
          }
          return true;
        })
        .toXmlNodes()
        .expand((e) => e)
        .map((e) => factory.load(this, e));
  }

  Stream<SArchive> _streamLoadedArchives() {
    return Stream.fromIterable(_loadedArchives.where((e) => !e.isDeleted));
  }

  /// Creates a new empty archive.
  /// This does not save the archive to the kit file immediately.
  /// It is added to the [_loadedArchives] list, and will be saved when [save] is called.
  Future<SArchive> createEmptyArchive() async {
    final archive =
        await SArchiveCreator(generateUniqueHash(await getArchiveHashes()))
            .create(this);
    _loadedArchives.add(archive);
    return archive;
  }

  /// Creates a new archive from a folder.
  /// Adds all of the files in the folder to the archive, making them relative to the archive.
  Future<SArchive> archiveFolder(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception("Path does not exist.");
    }
    final archive = await createEmptyArchive();
    for (final file in dir.listSync(recursive: true)) {
      /// Get all of the files in the current directory recursively,
      /// and add them to the new archive, making them relative to the archive.
      if (file is File) {
        await archive.addFile(file.path.relativeTo(path), file.openRead());
      }
    }
    return archive;
  }

  /// Returns a future [SArchive] from the kit file.
  /// If the archive is already loaded, it will return the loaded archive.
  Future<SArchive?> getArchive(String hash) async {
    if (_loadedArchives.any((e) => e.hash == hash)) {
      // if the archive is already loaded, return it.
      return _loadedArchives.firstWhere((e) => e.hash == hash);
    }
    final factory = getSFactory<SArchive>(); // get the archive factory
    final eventStream = _eventStream; // get the event stream
    final commits = await eventStream
        .selectSubtreeEvents((e) =>
            e.name == factory.tag &&
            e.attributes.any((element) =>
                element.name == "hash" &&
                element.value ==
                    hash)) // select the archive with the hash given.
        .toXmlNodes()
        .expand((e) => e)
        .map((e) => factory.load(this, e)) // load the archive
        .toList();
    if (commits.isEmpty) {
      return null;
    }
    final commit = commits.singleOrNull;
    _loadedArchives.add(commit!); // add the archive to the loaded archives.
    return commit;
  }

  /// Rehashes all of the archives in the kit file. Used when merging kit files.
  Future<void> rehashArchives([Set<String>? hashesToAvoid]) async {
    final hashes = await getArchiveHashes();
    final newHashes = <String>{...hashesToAvoid ?? {}};
    for (final hash in hashes) {
      final newHash = generateUniqueHash(newHashes); // generate a unique hash
      await _changeArchiveHash(hash, newHash); // change the hash
      newHashes.add(
          newHash); // add the new hash to the set, so that it is not used again.
    }
    await save(); // save the changes
  }

  /// Changes an archive's hash to a new hash.
  Future<void> _changeArchiveHash(String oldHash, String newHash) async {
    final archive = await getArchive(oldHash);
    archive!
        .markForDeletion(); // mark the old hash for deletion. This makes sure that the old version of the archive is not saved.
    archive.hash = newHash; // set the new hash
    final header = await getKitHeader(); // get the kit header
    for (final ref
        in header.getDescendants<SRArchive>(filter: (e) => e.hash == oldHash)) {
      // get all of the references to the archive in the kit header and change the hash.
      ref!.hash = newHash;
    }
  }

  /// Saves the kit file.
  /// This will save the kit header and all of the archives to the kit file.
  /// The header is saved to the top of the file, and the archives are saved to the bottom of the file.
  /// This will save all of the changes to the file.
  Future<void> save() async {
    final temp = File("$path.tmp"); // initialize the temp file object.
    if (await temp.exists()) {
      // if the temp file exists, delete it.
      await temp.delete(); // delete the temp file.
    }
    await temp.create(); // create the temp file.
    // Write the new kit header to the temp file.
    final header = (await getKitHeader()).toXmlString();
    Arceus.talker.info("Attempting to save SKit:\n $header");
    // Open the temp file for writing.
    final tempSink = temp.openWrite();

    // Write the new XML to temp file.
    final stream = Rx.merge<String>([
      Stream.fromIterable([header]),
      _streamUnloadedArchives().map((e) => e.toXmlString()),
      _streamLoadedArchives().map((e) => e.toXmlString())
    ])
        .toXmlEvents()
        .selectSubtreeEvents((event) {
          if (event.parent == null &&
              !["sere", "archive"].contains(event.localName)) {
            return false;
          }
          return true;
        })
        .toXmlString()
        .map<List<int>>((e) => e.codeUnits);
    await tempSink.addStream(stream.transform(gzip.encoder));
    await tempSink.flush();
    // Close the sink for the temp file.
    await tempSink.close();

    // Replace the old data in the file with the temp file's data.
    final sink = _file.openWrite();
    await sink.addStream(temp.openRead());

    // Close the sink.
    await sink.flush();
    await sink.close();

    // Delete the temp file.
    await temp.delete();

    discardChanges(); // Clear everything from memory.
  }

  /// Discards all of the changes to the kit file.
  /// This will unload all of the loaded archives, and clear the current kit header.
  void discardChanges() {
    _loadedArchives.clear();
    _kit = null;
  }
}

library skit;

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";
import "package:arceus/arceus.dart";
import "package:arceus/extensions.dart";
import "package:arceus/uuid.dart";
import "package:rxdart/rxdart.dart";
import 'package:xml/xml_events.dart';

import 'package:arceus/skit/sobject.dart' hide SInterface;
import 'package:arceus/skit/sobjects/sobjects.dart';
import "package:arceus/version_control/constellation/constellation.dart"
    show ConstellationFactory;
import "package:arceus/version_control/star/star.dart" show StarFactory;
import 'package:arceus/scripting/sinterface.dart' show SInterface;

import 'package:encrypt/encrypt.dart';
export "package:arceus/skit/sobject.dart";

part 'skit.factories.dart';
part 'skit.interface.dart';

/// The type of a [SKit].
/// [constellation] is the default type.
enum SKitType {
  unspecified,
  constellation,
  library,
}

/// Represents a compressed, encrypted XML file.
/// [SKit] is an abrivation for SERE kit, which is a reference to titanfall 2.
/// [SKit]s can contain any data that Arceus would ever need.
///
/// The two core [SObject]s which are tightly knit into [SKit]s are the [SHeader] and [SRoot]s.
/// The [SHeader] contains information about the kit (e.g. name of kit, version of arceus, the author of the kit, constellations, etc),
/// while the [SRoot]s can contain much larger sets of data or can be unrelated to the kit itself (e.g. save data, scripts, images, users, etc).
class SKit {
  /// Opens a kit file.
  static Future<SKit> open(String path,
      {SKitType? type, String encryptKey = "Arceus"}) async {
    final kit = SKit(path, encryptKey: encryptKey);
    if (!await kit.exists()) {
      throw Exception("SKit file does not exist!");
    }
    if (type != null && !await kit.isType(type)) {
      throw Exception("SKit file is not of the correct type!");
    }
    return kit;
  }

  /// The path to the kit file.
  final String path;

  /// This is the current key used to encrypt and decrypt the kit file.
  String _key;

  /// Used to encrypt the kit file with a new key, while keeping the old key
  /// to decrypt when transfering old data to the new key.
  String? _newKey;

  /// The key used to encrypt and decrypt the kit file.
  String get key => _newKey ?? _key;
  set key(String value) => _newKey = value;

  /// The key used to decrypt the kit file.
  Key get _decryptKey => Key.fromUtf8(_key.padRight(32, ".").substring(0, 32));

  /// The key used to encrypt the kit file.
  Key get _encryptKey =>
      Key.fromUtf8(_newKey?.padRight(32, ".").substring(0, 32) ??
          _key.padRight(32, ".").substring(0, 32));

  /// The encrypter and decrypter used to encrypt and decrypt the kit file.
  /// Separated to decrypt with the current key and encrypt with the new key.
  Encrypter get _decrypter => Encrypter(Fernet(_decryptKey));
  Encrypter get _encrypter => Encrypter(Fernet(_encryptKey));

  /// The additional bytes which are added to the kit file after encrypting.
  /// Used to chunk data properly when decrypting.
  static const int _encryptionExtraSize = 73;

  SKit(String path, {String encryptKey = ""})
      : path = path.fixPath(),
        _key = encryptKey;

  /// Returns the [File] of the kit file.
  File get _file => File(path);

  /// The currently loaded [SHeader] of the kit file.
  /// This will be null if no header has been got yet by calling [getHeader].
  /// This is seperate from the [SRoot]s because the header is always at the top of the file, and there is only one header.
  SHeader? _header;

  /// The currently loaded [SArchive]s of the kit file.
  /// This will be empty if no archive has been got yet by calling [getArchive].
  final Set<SRoot> _loadedRoots = {};

  /// This is used to store any deletion requests for any root in the file.
  /// To add a deletion request, use [addDeletionRequest].
  final Set<SIndent> _indents = {};

  /// Decrypts the data and sends it to the sink.
  void _decryptTransformer(List<int> data, EventSink<List<int>> sink) {
    sink.add(_decrypter.decryptBytes(Encrypted(Uint8List.fromList(data))));
  }

  void _encryptTransformer(List<int> data, EventSink<List<int>> sink) {
    final encrypted = _encrypter.encryptBytes(data);
    // Arceus.talker.debug(
    //     "Encrypted ${e.length} bytes to ${encrypted.bytes.length} bytes.");
    sink.add(encrypted.bytes);
  }

  /// Returns the stream of [_file].
  /// Do not use directly, and use [_eventStream] instead.
  Stream<List<int>>? get _byteStream => _file.existsSync()
      ? _file
          .openRead()
          .expand((e) => e)
          .chunk(SFile.chunkSize + _encryptionExtraSize)
          .transform(StreamTransformer.fromHandlers(
            handleData: _decryptTransformer,
            handleError: (er, st, sink) =>
                Arceus.talker.error("Error decrypting kit file", er, st),
          ))
          .transform(gzip.decoder)
      : null;

  /// Returns a stream of [XmlEvent]s from the file.
  /// This is used to parse the file data and get the xml events.
  Stream<List<XmlEvent>>? get _eventStream => _byteStream
      ?.transform<String>(utf8.decoder)
      .toXmlEvents()
      .normalizeEvents()
      .withParentEvents();

  /// Creates a new kit file.
  /// If the kit file already exists, it will throw an exception unless [overwrite] is true.
  /// If [type] is unspecified, it will be set to [SKitType.unspecified].
  /// Returns a future that completes when the kit file is created and saved.
  Future<SHeader> create(
      {bool overwrite = false, SKitType type = SKitType.unspecified}) async {
    if (await _file.exists() && !overwrite) {
      throw Exception("Kit file already exists.");
    } else if (await _file.exists() && overwrite) {
      await _file.delete();
    }
    discardChanges(); // clear the current kit from memory.
    _header = await SHeaderCreator(type).create();
    return _header!;
  }

  /// Returns true if the kit file exists.
  Future<bool> exists() => _file.exists();

  /// Gets the header of the kit file.
  /// If the header has already been loaded, it will return the cached header.
  Future<SHeader?> getHeader() async {
    if (_header == null) {
      final factory = getSFactory<SHeader>();

      _header = await (_eventStream!
          .selectSubtreeEvents((e) => e.localName == factory.tag)
          .toXmlNodes()
          .expand((e) => e)
          .whereType<XmlElement>()
          .map((e) => factory.load(e))
          .first);
    }
    return _header!..kit = this;
  }

  /// Returns true if the kit file is of the specified type.
  Future<bool> isType(SKitType type) async {
    final header = await getHeader();
    return header!.type == type;
  }

  /// Gets the root of the kit file of the specified type.
  /// If the root has already been loaded, it will return the cached root.
  /// If the root has not been loaded, it will be loaded and then returned.
  Future<T?> getRoot<T extends SRoot>(
      {bool Function(T root)? filterRoots,
      bool Function(XmlStartElementEvent e)? filterEvents,
      bool addToCache = true}) async {
    final roots = await getRoots<T>(
        filterRoots: filterRoots,
        filterEvents: filterEvents,
        addToCache: false);
    final root = roots.singleOrNull;
    if (addToCache) {
      _loadedRoots.add(root!);
    }
    return root;
  }

  /// Gets all of the roots of the kit file. of the specified type.
  /// If the roots have already been loaded, it will return the cached roots.
  /// If the roots have not been loaded, it will return.
  /// If [filterRoots] is specified, it will only return the roots that pass the filter.
  /// If [filterEvents] is specified, it will only return the events that pass the filter.
  /// If [addToCache] is true, it will add the roots to the cache.
  /// Returns a future that completes with the roots of the kit file.
  Future<Set<T?>> getRoots<T extends SRoot>(
      {bool Function(T root)? filterRoots,
      bool Function(XmlStartElementEvent)? filterEvents,
      bool addToCache = true}) async {
    final roots = _streamRoots(filterEvents: filterEvents)
        .whereType<T>()
        .where((e) => filterRoots == null || filterRoots(e));
    Set<T> rootsList = await roots.toSet();
    if (addToCache) {
      _loadedRoots.addAll(rootsList);
    }
    return rootsList;
  }

  /// Adds a root to the kit file.
  /// This will add the root to the kit file in memory, but will not save the changes to the file.
  /// To save the changes to the file, use [save].
  Future<void> addRoot(SRoot root) async {
    // Generate a unique hash for the root
    root.hash = generateUniqueHash(await usedRootHashes());
    Arceus.talker.debug(
        "New ${root.runtimeType} added to ${path.getFilename(withExtension: false)}! ($path)");

    // Adding the root to [_loadedRoots] is necessary for the [save] function to work.
    _loadedRoots.add(root);
  }

  /// Removes a root from the kit file.
  /// This will remove the root from the kit file in memory, and will not save its changes to the file.
  /// To save the changes to the file, use [save].
  void unloadRoot(SRoot root) => _loadedRoots.remove(root);

  /// Streams the roots of the kit file, getting their cached version if possible.
  /// This is used when saving or reading the kit file. Will not cache anything, but will stream the roots.
  /// To cache roots, use [getRoots] or [getRoot].
  Stream<SRoot> _streamRoots(
      {bool Function(XmlStartElementEvent)? filterEvents}) async* {
    final rootStream = _eventStream
            ?.selectSubtreeEvents(
                (e) => filterEvents == null || filterEvents(e))
            .toXmlNodes()
            .expand((e) => e)
            .whereType<XmlElement>()
            .map((e) => getSFactory(e.localName).load(e)
              ..kit = this) // Set the kit instance to this.
            .whereType<SRoot>() ??
        Stream.empty();
    final processedRoots = <SRoot>{};
    await for (final root in rootStream) {
      processedRoots.add(root);
      final loaded = _loadedRoots.where((e) => e == root).singleOrNull;
      SRoot sending = loaded ?? root;
      if (_indents.any((e) => e.isFor(sending) && e.isDeleted) ||
          sending.delete) {
        continue;
      }
      yield sending;
    }
    for (final root in _loadedRoots) {
      if (!processedRoots.contains(root)) {
        yield root;
      }
    }
  }

  Stream<String> _streamRootsAsXml() async* {
    await for (final root in _streamRoots()) {
      yield root.toXmlString();
    }
  }

  /// Returns the hashes used in the SKit file.
  Future<Set<String>> usedRootHashes<T extends SRoot>() async =>
      (await getRoots<T>(addToCache: false)).map((e) => e!.hash).toSet();

  /// Adds an indent to the kit file.
  /// Used for deletion.
  void addIndent(SIndent indent) => _indents.add(indent);

  /// Saves the kit file.
  /// This will save the kit header and all of the archives to the kit file.
  /// The header is saved to the top of the file, and the archives are saved to the bottom of the file.
  /// This will save all of the changes to the file.
  Future<void> save({String? encryptKey}) async {
    final stopwatch =
        Stopwatch(); // initialize a stopwatch for checking how long it takes to save.
    stopwatch.start();
    final temp = File("$path.tmp"); // initialize the temp file object.
    if (await temp.exists()) {
      // if the temp file exists, delete it.
      await temp.delete(); // delete the temp file.
    }
    // Write the new kit header to the temp file.
    Arceus.talker.debug("Attempting to save SKit. ($path)");

    // Ensure that the parent directory exists.
    await temp.ensureParentDirectory();

    // Open the temp file for writing.
    final tempSink = temp.openWrite();

    // Write the new XML to temp file.
    final stream = Rx.merge<String>([
      Stream.fromFuture(getHeader().then((e) => e!.toXmlString())),
      _streamRootsAsXml()
    ]);

    await tempSink.addStream(stream
        .transform(utf8.encoder)
        .transform(gzip.encoder)
        .expand((e) => e)
        .chunk(SFile.chunkSize) // Using chunk size in SFile, for consistency.
        .transform(
            StreamTransformer.fromHandlers(handleData: _encryptTransformer)));
    // Flush and Close the sink for the temp file.
    await tempSink.flush();
    await tempSink.close();

    // Replace the old key with the new key.
    if (_newKey != null) {
      _key = _newKey!;
      _newKey = null;
    }

    // Replace the old data in the file with the temp file's data.
    final sink = _file.openWrite();
    await sink.addStream(temp.openRead());

    // Close the sink.
    await sink.flush();
    await sink.close();

    // Delete the temp file.
    await temp.delete();

    discardChanges(); // Clear everything from memory.
    stopwatch.stop();
    Arceus.talker.info(
        "Successfully saved SKit in ${stopwatch.elapsedMilliseconds}ms! ($path)");
  }

  Future<void> exportToXMLFile(String path) async {
    final file = File(path);

    // Ensures that the parent directory exists.
    await file.ensureParentDirectory();
    final sink = file.openWrite();
    await sink.addStream(_byteStream!);
    await sink.flush();
    await sink.close();
  }

  /// Discards all of the changes to the kit file.
  /// This will unload all of the loaded archives, and clear the current kit header.
  void discardChanges() {
    _header = null;
    _loadedRoots.clear();
    _indents.clear();
  }
}

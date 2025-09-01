library skit;

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";
import "package:reyveld/reyveld.dart";
import "package:reyveld/extensions.dart";
import "package:reyveld/security/certificate/certificate.dart";
import "package:reyveld/security/policies/policies.dart";
import "package:reyveld/uuid.dart";
import "package:pointycastle/pointycastle.dart"
    show RSAPublicKey, RSAPrivateKey;
import "package:rxdart/rxdart.dart";
import 'package:xml/xml_events.dart';

import 'package:reyveld/skit/sobject.dart' hide SInterface;
import 'package:reyveld/skit/sobjects/sobjects.dart';
import 'package:reyveld/version_control/version_control.dart';
import 'package:reyveld/scripting/sinterface.dart' show SInterface;

import 'package:encrypt/encrypt.dart';
export "package:reyveld/skit/sobject.dart";

part 'skit.factories.dart';
part 'skit.interface.dart';

/// The type of a [SKit].
/// [constellation] is the default type.
enum SKitType {
  unspecified,
  constellation,
  authveld,
  authors,
}

typedef SKitKeyPair = ({RSAPrivateKey? private, RSAPublicKey public});

/// Represents a compressed, encrypted, and signed XML file.
/// [SKit] is an abrivation for SERE kit, which is a reference to titanfall 2.
/// [SKit]s can contain any data that Reyveld would ever need.
///
/// The two core [SObject]s which are tightly knit into [SKit]s are the [SHeader] and [SRoot]s.
/// The [SHeader] contains information about the kit (e.g. name of kit, version of Reyveld, the author of the kit, constellations, etc),
/// while the [SRoot]s can contain much larger sets of data (e.g. save data, scripts, images, users, etc).
///
/// [SKit]s are first compressed using GZip, then encrypted using Fernet, and finally is signed using RSA.
class SKit {
  /// Opens a kit file.
  static Future<SKit> open(
    String path, {
    SKitType? type,
    String encryptKey = "Arceus",
  }) async {
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

  /// The cached version of the public key.
  /// This is used to verify the signature of the kit file.
  RSAPublicKey? _cachedKitPublicKey;

  /// Returns the public key of the kit file.
  /// The public key is used to verify the signature of the kit file.
  /// If the file does not exist yet, it will return the public key of Reyveld.
  Future<RSAPublicKey> get kitPublicKey async {
    if (_cachedKitPublicKey == null) {
      if (!await _file.exists()) {
        _cachedKitPublicKey = await Reyveld.publicKey;
      } else {
        final header = await getHeader();
        if (header != null) {
          final author = await header.getChild<SRAuthor>()!.getRef();
          _cachedKitPublicKey = author!.publicKey;
        }
      }
    }
    return _cachedKitPublicKey!;
  }

  Future<SAuthor> get author async {
    final header = await getHeader();
    return (await header?.getChild<SRAuthor>()?.getRef()) ??
        await Reyveld.author.then((e) => e!.toSAuthor());
  }

  Future<SKitType> get type async =>
      (await getHeader())?.type ?? SKitType.unspecified;

  Future<Signer> _buildSigner([SKitKeyPair? keyPair]) async => Signer(RSASigner(
        RSASignDigest.SHA256,
        privateKey: keyPair?.private ?? await Reyveld.privateKey,
        publicKey: keyPair?.public ?? await Reyveld.publicKey,
      ));

  Future<Signer> get _verifier async =>
      Signer(RSASigner(RSASignDigest.SHA256, publicKey: await kitPublicKey));

  Stream<List<int>> _sign(Stream<List<int>> data,
      {SKitKeyPair? keyPair}) async* {
    await for (final bytes in data) {
      final signer = await _buildSigner(keyPair);
      final signature = signer.signBytes(bytes);
      yield [...signature.bytes, ...bytes];
    }
  }

  /// Verifies the signature of the current kit file.
  Future<bool> verify({bool onTempFile = false}) async {
    final verifier = await _verifier;
    final file = onTempFile ? File("$path.tmp") : _file;
    if (!await file.exists()) {
      return true;
    }
    final stream = file.openRead();
    await for (final bytes in stream
        .rechunk(SFile.chunkSize + _encryptionExtraSize + _signExtraSize)) {
      final signature =
          Encrypted(Uint8List.fromList(bytes.sublist(0, _signExtraSize)));
      final content = bytes.sublist(_signExtraSize);
      if (!verifier.verifyBytes(content, signature)) {
        stream.drain();
        return false;
      }
    }
    return true;
  }

  Stream<List<int>> _removeSign(Stream<List<int>> data) async* {
    await for (final bytes in data) {
      if (bytes.length < _signExtraSize) {
        throw Exception("Invalid signature length.");
      }
      final content = bytes.sublist(_signExtraSize);
      yield content;
    }
  }

  Future<bool> isVerifiedAndTrusted() async {
    if (await verify()) {
      return await author.then((e) => e.isTrusted());
    }
    return false;
  }

  /// The additional bytes which are added to the kit file after encrypting.
  /// Used to chunk data properly when decrypting.
  static const int _encryptionExtraSize = 73;

  /// The size of a signature in bytes (meaning the bytes before the actual data).
  static const int _signExtraSize = 256;

  SKit(String path, {String encryptKey = ""})
      : path = path.resolvePath(),
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
  /// To add a deletion request, use [addIndent].
  final Set<SIndent> _indents = {};

  /// Decrypts the data and sends it to the sink.
  void _decryptTransformer(List<int> data, EventSink<List<int>> sink) {
    sink.add(_decrypter.decryptBytes(Encrypted(Uint8List.fromList(data))));
  }

  void _encryptTransformer(List<int> data, EventSink<List<int>> sink) {
    final encrypted = _encrypter.encryptBytes(data);
    sink.add(encrypted.bytes);
  }

  /// Returns the stream of [_file].
  /// Do not use directly, and use [_eventStream] instead.
  Stream<List<int>>? get _byteStream => _file.existsSync()
      ? _file
          .openRead()
          .rechunk(SFile.chunkSize + _encryptionExtraSize + _signExtraSize)
          .transform(StreamTransformer.fromBind(
            _removeSign,
          )) // Verify the signature of the kit file.
          .transform(StreamTransformer.fromHandlers(
            handleData: _decryptTransformer,
            handleError: (er, st, sink) =>
                Reyveld.talker.error("Error decrypting kit file", er, st),
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
    _header = await SHeaderCreator(type: type).create();
    final author = await Reyveld.author.then((e) => e!.toSAuthor());
    await addRoot(author);
    final ref = await author.newIndent();
    _header!.addChild(ref);
    return _header!;
  }

  /// Returns true if the kit file exists.
  Future<bool> exists() => _file.exists();

  /// Gets the header of the kit file.
  /// If the header has already been loaded, it will return the cached header.
  Future<SHeader?> getHeader() async {
    if (_header == null) {
      if (!_file.existsSync()) {
        return await SHeaderCreator().create();
      }
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
  ///
  /// If the roots have already been loaded, it will return the cached roots.
  /// If the roots have not been loaded, it will return.
  /// If [filterRoots] is specified, it will only return the roots that pass the filter.
  /// If [filterEvents] is specified, it will only return the events that pass the filter.
  ///
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
    final loads = {..._loadedRoots};
    await for (final root in rootStream) {
      final loaded = loads.where((e) => e == root).singleOrNull;
      if (loaded != null) {
        loads.remove(loaded);
      }
      SRoot sending = loaded ?? root;
      if (_indents.any((e) => e.isFor(sending) && e.isDeleted) ||
          sending.delete) {
        continue;
      }
      yield sending;
    }
    yield* Stream.fromIterable(
        loads.where((e) => !_indents.any((i) => i.isFor(e) && i.isDeleted)));
  }

  /// Streams the roots of the kit file as xml strings.
  /// This will stream all of the roots of the kit file as xml strings.
  /// The roots are streamed in the order they are stored in the kit file.
  /// This will cache the roots, so if you want to stream the roots without caching, use [_streamRoots].
  Stream<String> _streamRootsAsXml() async* {
    await for (final root in _streamRoots()) {
      yield root.toXmlString();
    }
  }

  /// Returns the hashes used in the SKit file.
  Future<Set<String>> usedRootHashes() async => (await getRoots(
        addToCache: false,
      ))
          .map((e) => e!.hash)
          .toSet();

  /// Adds an indent to the kit file.
  /// Used for deletion.
  void addIndent(SIndent indent) => _indents.add(indent);

  /// Checks to see if the hash is marked for deletion.
  bool isMarkedForDeletion(String hash) {
    return _indents.any((e) => e.hash == hash && e.isDeleted);
  }

  /// Saves the kit file.
  /// This will save the kit header and all of the archives to the kit file.
  /// The header is saved to the top of the file, and the archives are saved to the bottom of the file.
  /// This will save all of the changes to the file.
  Future<void> save({String? encryptKey, SKitKeyPair? keyPair}) async {
    if (!await isVerifiedAndTrusted()) {
      throw TrustException(this, await kitPublicKey);
    }
    final stopwatch =
        Stopwatch(); // initialize a stopwatch for checking how long it takes to save.
    stopwatch.start();
    final temp = File("$path.tmp"); // initialize the temp file object.
    if (await temp.exists()) {
      // if the temp file exists, delete it.
      await temp.delete(); // delete the temp file.
    }
    // Ensure that the parent directory exists.
    await temp.ensureParentDirectory();

    // Open the temp file for writing.
    final tempSink = temp.openWrite();

    // Calls onSave on the header to do any necessary changes before saving.
    await getHeader().then((header) => header!.onSave(this));

    // Write the new XML to temp file.
    final stringStream = Rx.merge<String>([
      Stream.fromFuture(getHeader().then((e) => e!.toXmlString())),
      _streamRootsAsXml()
    ]);

    // Will override the kit file's public key if it has one.
    final publicKey = keyPair?.public ?? await Reyveld.publicKey;

    _cachedKitPublicKey =
        publicKey; // Cache our own public key. Used when signing another person's kit file with our own keys.

    final byteStream = stringStream
        .transform(utf8.encoder)
        .transform(gzip.encoder)
        .rechunk(SFile.chunkSize) // Using chunk size in SFile, for consistency.
        .transform(
            StreamTransformer.fromHandlers(handleData: _encryptTransformer))
        .transform(
            StreamTransformer.fromBind((e) => _sign(e, keyPair: keyPair)));

    await tempSink.addStream(byteStream);
    // Flush and Close the sink for the temp file.
    await tempSink.flush();
    await tempSink.close();

    // Replace the old key with the new key.
    if (_newKey != null) {
      _key = _newKey!;
      _newKey = null;
    }

    // Verify the temp file.
    if (!await verify(onTempFile: true)) {
      throw "Save verification failed! The kit file may be corrupted!";
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
  }

  Future<void> exportToXMLFile(String path) async {
    if (!await isVerifiedAndTrusted()) {
      throw TrustException(this, await kitPublicKey);
    }
    final file = File(path.resolvePath());

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

class TrustException implements Exception {
  final RSAPublicKey publicKey;
  final SKit kit;
  TrustException(this.kit, this.publicKey);

  @override
  String toString() =>
      "The author of \"${kit.path}\" is not trusted! Please trust the author before using this kit.";
}

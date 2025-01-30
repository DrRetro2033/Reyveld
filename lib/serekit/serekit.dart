import "dart:async";
import "dart:convert";
import "dart:io";
import "package:arceus/updater.dart";
import "package:arceus/uuid.dart";
import "package:arceus/version_control/constellation.dart";
import "package:arceus/version_control/star.dart";
import "package:xml/xml.dart";
import 'package:xml/xml_events.dart';
import 'package:arceus/serekit/file_system.dart';

export 'package:xml/xml.dart';

/// The set of all [SFactory] objects.
/// This is used to load [SObject]s from xml.
final Set<SFactory> _sobjectFactories = {
  ConstFactory(),
  StarFactory(),
  KitHeaderFactory(),
  SArchiveFactory(),
  SFileFactory(),
};

/// Get the factory for the given [SObject] subclass.
/// Returns null if not found.
SFactory<T>? getSFactory<T extends SObject>(String? tag) => _sobjectFactories
    .whereType<SFactory<T>?>()
    .firstWhere((e) => e!.tag == tag, orElse: () => null);

/// Represents a compressed XML file.
/// [SKit] is an abrivation for SERE kit, which is a reference to titanfall 2.
/// [SKit]s can contain any data that Arceus needs. It can contain constellations, stars, users, settings, files, and more.
class SKit {
  /// The path to the kit file.
  final String path;

  /// The loaded [KitHeader] of the kit file.
  /// This will be null if the kit file has not been loaded yet by calling [getKitHeader].
  /// Every subsequent call to [getKitHeader] will return this.
  KitHeader? _kit;
  SKit(this.path);

  /// Returns the [File] of the kit file.
  File get _file => File(path);

  /// The currently loaded [SArchive]s of the kit file.
  /// This will be empty if no archive has been got yet by calling [getArchive].
  final List<SArchive> _loadedArchives = [];

  /// Returns the stream of [_file], decompressing if possible.
  /// If decompression fails, it will fallback on the raw data of the file.
  /// Do not use directly, and use [_eventStream] instead.
  Stream<List<int>> get _byteStream async* {
    final stream = _file.openRead();
    await for (final chunk in stream) {
      try {
        // Attempt to decompress using gzip
        final decompressedData = gzip.decode(chunk);
        yield decompressedData;
      } catch (e) {
        // If decompression fails, assume it's raw data
        yield chunk;
      }
    }
  }

  /// Returns a stream of [XmlEvent]s from the file.
  /// This is used to parse the file data and get the xml events.
  Stream<List<XmlEvent>> get _eventStream => _byteStream
      .transform(utf8.decoder)
      .toXmlEvents()
      .normalizeEvents()
      .withParentEvents();

  /// Returns the [KitHeader] of the kit file.
  /// This is used when loading a kit file.
  FutureOr<KitHeader> getKitHeader() async {
    if (_kit == null) {
      final factory = KitHeaderFactory();
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
  Future<KitHeader> create(
      {bool overwrite = false, SKitType type = SKitType.unspecified}) async {
    if (await _file.exists() && !overwrite) {
      throw Exception("Kit file already exists.");
    }
    discardChanges(); // clear the current kit from memory
    if (!await _file.exists()) {
      await _file.create(recursive: true);
    }
    final factory = KitHeaderFactory();
    _kit = await factory.create(this, {"type": type});
    return _kit!;
  }

  /// Returns a future set of all of the hashes used by the archives in the kit.
  /// This is used when creating a new archive.
  Future<Set<String>> _getArchiveHashes() async {
    final factory = SArchiveFactory();
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
  Future<String> generateUniqueArchiveHash() async =>
      generateUniqueHash(await _getArchiveHashes());

  /// Returns a stream of [SArchive] objects.
  /// This is used when saving an already existing kit file.
  /// Does not stream loaded, or marked for deletion archives.
  Stream<SArchive> _streamUnloadedArchives() {
    final factory = SArchiveFactory();
    return _eventStream
        .selectSubtreeEvents(
            (e) => e.name == factory.tag) // select archives tags
        .selectSubtreeEvents((e) => !e.attributes.any((e) =>
            e.name == "hash" &&
            SArchive.markedForDeletion.contains(
                e.value))) // select archives that are not marked for deletion
        .selectSubtreeEvents((e) => !e.attributes.any((e) =>
            e.name == "hash" &&
            _loadedArchives.any((a) =>
                a.hash == e.value))) // select archives that are not loaded
        .toXmlNodes()
        .expand((e) => e)
        .map((e) => factory.load(this, e));
  }

  /// Creates a new archive.
  /// This does not save the archive to the kit file immediately.
  /// It is added to the [_loadedArchives] list, and will be saved when [save] is called.
  Future<SArchive> createArchive() async {
    final factory = SArchiveFactory();
    final hash = await generateUniqueArchiveHash();
    final archive = await factory.create(this, {"hash": hash});
    _loadedArchives.add(archive);
    return archive;
  }

  Future<SArchive> getArchive(String hash) async {
    if (_loadedArchives.any((e) => e.hash == hash)) {
      // if the archive is already loaded, return it.
      return _loadedArchives.firstWhere((e) => e.hash == hash);
    }
    final factory = SArchiveFactory(); // get the archive factory
    final eventStream = _eventStream; // get the event stream
    final commit = (await eventStream
            .selectSubtreeEvents((e) =>
                e.name == factory.tag &&
                e.attributes.any((element) =>
                    element.name == "hash" &&
                    element.value ==
                        hash)) // select the archive with the hash given.
            .toXmlNodes()
            .expand((e) => e)
            .map((e) => factory.load(this, e)) // load the archive
            .toList())
        .first;
    _loadedArchives.add(commit); // add the archive to the loaded archives.
    return commit;
  }

  // Future<void> test() async {
  //   final info = await getKitHeader();
  //   print(info.createdOn);
  //   final constellation = info.getChildren<Constellation>().first;
  //   print(constellation!.name);
  //   final star = constellation.getChild<Star>();
  //   print(star!.name);
  //   star.name = "Test Star";
  //   final commit = await createArchive();
  //   print(commit.hash);

  //   final file = await SFileFactory().create(this, {
  //     "file": File(
  //         "C:/Users/Colly/OneDrive/Documents/Pokemon/0003 - DaisyTestTES - 0B1CBBBB6F73.pk9")
  //   });
  //   commit.addFile(file);

  //   await save();
  //   final archive =
  //       await info.getChild<Constellation>()!.getChild<Star>()!.archive;

  //   final file2 = File("../test.pk9");

  //   await file2.create();
  //   await file2.writeAsBytes(archive
  //       .getFile(
  //           "C:/Users/Colly/OneDrive/Documents/Pokemon/0003 - DaisyTestTES - 0B1CBBBB6F73.pk9")!
  //       .data);
  // }

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
    final xml = (await getKitHeader()).toXmlString();
    await temp.writeAsString(xml);
    // Open the temp file for writing.
    final tempSink = temp.openWrite(mode: FileMode.append);

    // Write the unloaded archives to the temp file.
    await tempSink.addStream(_streamUnloadedArchives()
        .map((e) => e.toXmlString())
        .transform(utf8.encoder));
    await tempSink.flush();
    // Write the loaded archives to the temp file.
    await tempSink.addStream(
        Stream.fromIterable(_loadedArchives.map((e) => e.toXmlString()))
            .transform(utf8.encoder));

    // Close the sink.
    await tempSink.close();

    // Replace the old data in the file with the temp file's data.
    final sink = _file.openWrite();
    await sink.addStream(temp.openRead().transform(gzip.encoder));

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

enum SKitType { unspecified, constellation, constellationPack, addon, settings }

/// The header node of a SERE kit file.
/// This is the top level node of the kit file, and contains information about the kit, and the contents of the kit.
class KitHeader extends SObject {
  KitHeader(super.kit, super._node);

  DateTime get createdOn =>
      DateTime.parse(get("createdOn") ?? DateTime.now().toIso8601String());
  set createdOn(DateTime value) {
    if (!has("createdOn")) {
      set("createdOn", value.toIso8601String());
    }
  }

  DateTime get lastModified =>
      DateTime.parse(get("lastModified") ?? DateTime.now().toIso8601String());
  set lastModified(DateTime value) {
    set("lastModified", value.toIso8601String());
  }

  String get version => get("version") ?? Updater.currentVersion.toString();

  SKitType get type => SKitType.values[int.parse(get("type") ?? "0")];
}

class KitHeaderFactory extends SFactory<KitHeader> {
  @override
  String get tag => "sere";

  @override
  get requiredAttributes => {
        "type": (e) => e is SKitType,
      };

  @override
  KitHeader load(SKit kit, XmlNode node) {
    return KitHeader(kit, node);
  }

  @override
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic> attributes = const {}]) {
        builder.element("sere", nest: () {
          builder.attribute("createdOn", DateTime.now().toIso8601String());
          builder.attribute("lastModified", DateTime.now().toIso8601String());
          builder.attribute("version", Updater.currentVersion.toString());
          builder.attribute(
              "type", (attributes["type"] as SKitType).index.toString());
        });
      };
}

/// A object that wraps around a [XmlNode] and provides a simple API to access its attributes, children, and more.
/// SObjects must have a [SFactory] object inside the [_sobjectFactories] set in order to be parsed from xml.
abstract class SObject {
  final XmlNode _node;
  final SKit kit;

  SObject(this.kit, this._node);

  /// Sets a attribute of the xml node.
  /// Should be used in a setter method:
  /// ```dart
  /// set name(String value) => set("name", value);
  /// ```
  void set(String key, dynamic value) {
    _node.setAttribute(key, value.toString());
  }

  /// Gets a attribute of the xml node.
  /// Should be used in a getter method:
  /// ```dart
  /// String get name => get("name");
  /// ```
  String? get(String key) {
    return _node.getAttribute(key);
  }

  /// Returns the parent of the xml node, if it has one.
  XmlNode? get parent => _node.parent;

  /// Returns the inner text of the xml node.
  String? get innerText {
    return _node.innerText;
  }

  /// Checks if the xml node has an attribute.
  /// Should be used when checking if an attribute exists, if needed.
  bool has(String key) => _node.getAttribute(key) != null;

  /// Adds a child [SObject] to the xml node.
  /// Removes the child from its current parent to safely move it to the new parent.
  void addChild(SObject child) {
    if (child.parent != null) child._node.remove();
    _node.children.add(child._node);
  }

  /// Removes a child [SObject] from the xml node.
  void removeChild(SObject child) {
    if (_node.contains(child._node)) {
      child._node.remove();
    }
  }

  /// Returns a list of children of the xml node, with the specific type.
  List<T?> getChildren<T extends SObject>() {
    List<T?> children = [];
    for (var child in _node.childElements) {
      SFactory<T>? factory = getSFactory<T>(child.name.local);
      if (factory != null) {
        children.add(factory.load(kit, child));
      }
    }
    return children;
  }

  /// Returns a child of the xml node, with the specific type.
  /// If [filter] is provided, it will only return the first child that matches the filter.
  T? getChild<T extends SObject>({bool Function(T)? filter}) {
    for (var child in _node.childElements) {
      SFactory<T>? factory = getSFactory<T>(child.name.local);
      if (factory != null) {
        T obj = factory.load(kit, child);
        if (filter != null && !filter(obj)) {
          continue;
        }
        return obj;
      }
    }
    return null;
  }

  /// Returns a list of descendants of the xml node, with the specific type.
  List<T?> getDescendants<T extends SObject>({bool Function(T)? filter}) {
    List<T?> descendants = [];
    for (var child in _node.descendantElements) {
      SFactory<T>? factory = getSFactory<T>(child.name.local);
      if (factory != null) {
        T obj = factory.load(kit, child);
        if (filter != null && !filter(obj)) {
          continue;
        }
        descendants.add(obj);
      }
    }
    return descendants;
  }

  /// Returns the xml node as a xml String.
  String toXmlString() => "\n${_node.toXmlString(pretty: true)}";
}

/// A base factory for creating [SObject]s.
/// Subclasses should be created as follows:
/// ```dart
/// class MySFactory extends SFactory<MySObject> {
///   ...
/// }
/// ```
abstract class SFactory<T extends SObject> {
  /// The tag of the associated xml node.
  /// Will be checked if unique in [_sobjectFactories].
  String get tag;

  /// The attributes that are required for creation of the object.
  /// The values are functions for not only checking if a value is in the correct format,
  /// but also if they are the correct type.
  /// If an attribute is not required, it should not be included in [optionalAttributes].
  ///
  /// Example:
  /// ```dart
  /// get requiredAttributes => {
  ///   "name": (value) => value is String && value.length <= 20,
  ///   "age": (value) => value is int,
  ///   ...
  /// };
  /// ```
  Map<String, FutureOr<bool> Function(dynamic)> get requiredAttributes => {};

  /// The attributes that are optional for creation of the object.
  /// The values are functions for checking if a value is in the correct format and is the correct type.
  /// If an attribute is not optional, it should be included in [requiredAttributes].
  ///
  /// Example:
  /// ```dart
  /// get optionalAttributes => {
  ///   "name": (value) => value is String && value.length <= 20,
  ///   "age": (value) => value is int,
  ///   ...
  /// };
  /// ```
  Map<String, FutureOr<bool> Function(dynamic)> get optionalAttributes => {};

  /// Loads the [SObject] from the xml node.
  /// The [SKit] and the [XmlNode] are passed for accessing the underlying xml data,
  /// and the file it came from.
  T load(SKit kit, XmlNode node);

  /// Creates a [SObject] from scratch, with the given attributes.
  /// Returns the new object as a futureor of the type [T].
  FutureOr<T> create(SKit kit,
      [Map<String, dynamic> attributes = const {}]) async {
    if (requiredAttributes.isNotEmpty) {
      for (var attribute in requiredAttributes.keys) {
        if (!attributes.containsKey(attribute) ||
            !await requiredAttributes[attribute]!(attributes[attribute])) {
          throw ArgumentError(
              "Missing '$attribute'. Attributes needed: ${requiredAttributes.keys.join(", ")}");
        }
      }
    }
    if (optionalAttributes.isNotEmpty) {
      for (var attribute in optionalAttributes.keys) {
        if (attributes.containsKey(attribute) &&
            !await optionalAttributes[attribute]!(attributes[attribute])) {
          throw ArgumentError("Invalid optional value for '$attribute'.");
        }
      }
    }
    final builder = XmlBuilder();
    await creator(builder, attributes);
    final frag = builder.buildDocument();
    return load(kit, frag.rootElement);
  }

  /// The function that creates the xml node.
  /// A [XmlBuilder] and an map of attributes is passed in for creating the xml node.
  /// The creator can be synchronous or asynchronous, it doesn't matter. What does matter
  /// is if there are essensial attributes that need to be given before creating the xml node.
  /// If there are essensial attributes, they should be in the [requiredAttributes] map.
  FutureOr<void> Function(XmlBuilder builder, [Map<String, dynamic> attributes])
      get creator;

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SFactory) return false;
    if (other.tag != tag) return false;
    return true;
  }

  @override
  int get hashCode => tag.hashCode;
}

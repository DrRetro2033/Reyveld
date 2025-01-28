import "dart:async";
import "dart:convert";
import "dart:io";
import "package:arceus/updater.dart";
import "package:arceus/version_control/constellation.dart";
import "package:arceus/version_control/star.dart";
import "package:xml/xml.dart";
import 'package:xml/xml_events.dart';

export 'package:xml/xml.dart';

final Set<SFactory> _sobjectFactories = {
  ConstFactory(),
  StarFactory(),
  KitFactory(),
};

/// Get the factory for the given [SObject] subclass.
///
SFactory<T>? getSFactory<T extends SObject>(String? tag) => _sobjectFactories
    .whereType<SFactory<T>?>()
    .firstWhere((e) => e!.tag == tag, orElse: () => null);

/// Represents a compressed XML file.
/// [SKit] is an abrivation for SERE kit, which is a reference to titanfall 2.
/// SKits can contain any data that Arceus needs. It can contain an addon, constellation, stars, users, files, and more.
class SKit {
  final String path;
  SKit(this.path);

  File get _file => File(path);

  /// The previously loaded bytes of the file.
  /// This is used not only to make subsequent calls for the file data faster,
  /// but also to make sure that when writing to the file, the xml package does not
  /// read directly from the file, which causes a error to be thrown.
  ///
  /// This should always be compressed, and not the full file. [_eventStream] will uncompress the file when needed.
  List<int>? _loadedBytes;

  /// Returns a new stream of [_loadedBytes], loading from the file first if needed.
  /// Do not use directly, and use [_eventStream] instead.
  Future<Stream<List<int>>> get _byteStream async {
    _loadedBytes ??= (await _file.openRead().transform(gzip.encoder).toList())
        .expand((e) => e)
        .toList();
    return Stream.fromIterable([_loadedBytes!]);
  }

  /// Returns a stream of [XmlEvent]s from the file.
  /// This is used to parse the file data and get the xml events.
  Future<Stream<List<XmlEvent>>> get _eventStream async => (await _byteStream)
      .transform(gzip.decoder)
      .transform(utf8.decoder)
      .toXmlEvents()
      .normalizeEvents()
      .withParentEvents();

  Future<Kit> getKit() async {
    final factory = KitFactory();
    final eventStream = await _eventStream;
    final kit = (await eventStream
            .selectSubtreeEvents((e) => e.name == factory.tag)
            .toXmlNodes()
            .expand((e) => e)
            .map((e) => factory.load(e))
            .toList())
        .first;
    return kit;
  }

  Future<void> test() async {
    final info = await getKit();
    print(info.createdOn);
    final constellation = info.getChildren<Constellation>().first;
    print(constellation!.name);
    final star = constellation.getChild<Star>();
    print(star!.name);
    star.name = "Test Star";
    await save(info);
    final info2 = await getKit();
    print(info2.getChild<Constellation>()!.getChild<Star>()!.name);
  }

  Future<void> save(Kit kit) async {
    final xml = kit.toXmlString();
    await _file.writeAsString(xml);
    _loadedBytes = gzip.encode(utf8.encode(xml));
  }
}

enum SKitType { unspecified, constellation, constellationPack, addon, settings }

/// The root node of a SERE kit file.
/// This is the top level node of the kit file, and contains information about the kit, and the contents of the kit.
class Kit extends SObject {
  Kit(super._node);

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

class KitFactory extends SFactory<Kit> {
  @override
  String get tag => "sere";

  @override
  Kit load(XmlNode node) {
    return Kit(node);
  }

  @override
  void create(XmlBuilder builder, [Map<String, String> overrides = const {}]) {
    builder.element("sere", nest: () {
      builder.attribute("createdOn", DateTime.now().toIso8601String());
      builder.attribute("lastModified", DateTime.now().toIso8601String());
      builder.attribute("version", Updater.currentVersion.toString());
      if (overrides.containsKey("type")) {
        builder.attribute("type", overrides["type"]);
      } else {
        builder.attribute("type", SKitType.unspecified.index.toString());
      }
    });
  }
}

/// A object that wraps around a [XmlNode] and provides a simple API to access its attributes, children, and more.
/// SObjects must have a [SFactory] object inside the [_sobjectFactories] set in order to be parsed from xml.
abstract class SObject {
  final XmlNode _node;

  SObject(this._node);

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

  /// Checks if the xml node has an attribute.
  /// Should be used when checking if an attribute exists, if needed.
  bool has(String key) => _node.getAttribute(key) != null;

  /// Adds a child [SObject] to the xml node.
  void addChild(SObject child) => _node.children.add(child._node);

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
        children.add(factory.load(child));
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
        T obj = factory.load(child);
        if (filter != null && !filter(obj)) {
          continue;
        }
        return obj;
      }
    }
    return null;
  }

  String toXmlString() => _node.toXmlString();
}

/// A base factory for creating [SObject]s.
/// Subclasses should be created as follows:
/// ```dart
/// class MySFactory extends SFactory<MySObject> {
///   ...
/// }
/// ```
abstract class SFactory<T extends SObject> {
  String get tag;

  T load(XmlNode node);

  void create(XmlBuilder builder, [Map<String, String> overrides = const {}]);

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

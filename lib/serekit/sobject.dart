import 'dart:async';

import 'package:arceus/serekit/serekit.dart';
import 'package:arceus/uuid.dart';
import 'package:xml/xml.dart';

export 'package:xml/xml.dart';
export 'package:arceus/serekit/serekit.dart';
export 'package:arceus/build_runner/annotations.dart';

/// This file consists of three core elements for both creating and loading [SObject]s:
/// - The [SObject] itself.
/// - The [SFactory] of the [SObject] used for loading (read description for more info).
/// - The [SCreator] of the [SObject] used for creating (read description for more info).

/// A object that wraps around a [XmlNode] and provides a simple API to access its attributes, children, and more.
/// SObjects must have a [SFactory] object inside the [_sobjectFactories] (inside serekit.g.dart) set in order to be parsed from xml.
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
  String? get innerText => _node.innerText;

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

  void unparent() {
    _node.remove();
  }

  /// Returns a list of children of the xml node, with the specific type.
  List<T?> getChildren<T extends SObject>() {
    List<T?> children = [];
    for (var child in _node.childElements) {
      final factory = getSFactory(child.name.local);
      if (factory is! SFactory<T>) continue;
      children.add(factory.load(kit, child));
    }
    return children;
  }

  /// Returns a child of the xml node, with the specific type.
  /// If [filter] is provided, it will only return the first child that matches the filter.
  T? getChild<T extends SObject>({bool Function(T)? filter}) {
    for (var child in _node.childElements) {
      final factory = getSFactory(child.name.local);
      if (factory is! SFactory<T>) {
        continue;
      }
      T obj = factory.load(kit, child);
      if (filter != null && !filter(obj)) {
        continue;
      }
      return obj;
    }
    return null;
  }

  /// Returns the parent of the xml node, if it has one.
  /// If [filter] is provided, it will only return the parent that matches the filter.
  T? getParent<T extends SObject>({bool Function(T)? filter}) {
    if (_node.parentElement == null) return null;
    final factory = getSFactory(_node.parentElement!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(kit, _node.parentElement!);
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns a list of descendants of the xml node, with the specific type.
  List<T?> getDescendants<T extends SObject>({bool Function(T)? filter}) {
    List<T?> descendants = [];
    for (var child in _node.descendantElements) {
      final factory = getSFactory(child.name.local);
      if (factory is! SFactory<T>) continue;
      T obj = factory.load(kit, child);
      if (filter != null && !filter(obj)) {
        continue;
      }
      descendants.add(obj);
    }
    // sort descendants by depth, with the deepest last.
    descendants.sort((a, b) => a!.getDepth().compareTo(b!.getDepth()));
    return descendants;
  }

  /// Returns the closest ancestor of the xml node, if it has one.
  List<T?> getAncestors<T extends SObject>({bool Function(T)? filter}) {
    final ancest = <T>[];
    Iterable<XmlElement> ancestors = _node.ancestorElements;
    for (var ancestor in ancestors) {
      final factory = getSFactory(ancestor.name.local);
      if (factory is! SFactory<T>) continue;
      T obj = factory.load(kit, ancestor);
      if (filter != null && !filter(obj)) {
        continue;
      }
      ancest.add(obj);
    }
    return ancest;
  }

  /// Returns the sibling of the xml node above it, if it has one.
  T? getSiblingAbove<T extends SObject>({bool Function(T)? filter}) {
    if (_node.previousElementSibling == null) return null;
    final factory = getSFactory(_node.previousElementSibling!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(kit, _node.previousElementSibling!);
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns the sibling of the xml node below it, if it has one.
  T? getSiblingBelow<T extends SObject>({bool Function(T)? filter}) {
    if (_node.nextElementSibling == null) return null;
    final factory = getSFactory(_node.nextElementSibling!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(kit, _node.nextElementSibling!);
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  int getDepth() {
    return _node.depth;
  }

  /// Returns the xml node as a xml String.
  String toXmlString() => _node.toXmlString(pretty: true, newLine: "\n");
}

/// A base class for all root objects.
/// Root objects are objects that are at the root of the skit file.
abstract class SRoot extends SObject {
  SRoot(super.kit, super.node);

  bool delete = false;

  String get hash => get("hash")!;
  set hash(String value) => set("hash", value);

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SRoot) return false;
    if (other.runtimeType != runtimeType) return false;
    if (other.hash != hash) return false;
    return true;
  }

  @override
  int get hashCode => hash.hashCode;

  void markForDeletion() {
    delete = true;
  }
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

  /// Loads the [SObject] from the xml node.
  /// The [SKit] and the [XmlNode] are passed for accessing the underlying xml data,
  /// and the file it came from.
  T load(SKit kit, XmlNode node);

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

/// A reference to another [SObject].
/// This is used when an object needs to reference another object that could be anywhere in the xml file.
abstract class SReference<T extends SObject> extends SObject {
  SReference(super.kit, super._node);
  FutureOr<T?> getRef();
}

/// A base creator for creating [SObject]s.
/// Creation was at first delegated to [SFactory], however
/// it was moved to its own base class for more stricter
/// control over the creation process.
///
/// All subclasses should implement the [creator] method,
/// To create a [SObject], you should call the [create] method.
///
/// Example:
/// ```dart
/// class MySCreator extends SCreator<MySObject> {
///
///   /// This is an example of required parameters that must be given to the [SCreator].
///   final String name;
///
///   /// This is an example of optional parameters that can be given to the [SCreator].
///   final DateTime? date;
///
///   MySCreator(this.name, {this.date = null});
///
///   @override
///   get creator => (builder) {
///     /// No need to add element here, it will be added by the creator function
///     /// as it is a nested builder.
///     builder.attribute("name", name);
///     builder.attribute("date", (date ?? DateTime.now()).toIso8601String());
///   }
/// }
/// ```
abstract class SCreator<T extends SObject> {
  SCreator();

  FutureOr<T> create(SKit kit) async {
    final builder = XmlBuilder();

    /// Does something before creation asyncronously
    await beforeCreate(kit);

    builder.element(getSFactory<T>().tag, nest: () {
      creator(builder);
    });

    final frag = builder.buildDocument(); // build the document

    /// load the [SObject]
    return getSFactory<T>().load(kit, frag.rootElement);
  }

  FutureOr<void> Function(SKit kit) get beforeCreate => (kit) async {
        return;
      };

  /// Creator must never be asynchronous, as the xml package does not play nicely with it.
  /// It must be synchronous. However, if you need to use asyncronous code,
  /// use [beforeCreate] to do stuff before creating the [SObject].
  void Function(XmlBuilder builder) get creator;
}

abstract class SRootCreator<T extends SRoot> {
  SRootCreator();
  FutureOr<T> create(SKit kit) async {
    final builder = XmlBuilder();

    /// Does something before creation asyncronously
    await beforeCreate(kit);

    final usedHashes = await kit.usedRootHashes<T>();

    final hash = generateUniqueHash(usedHashes);

    builder.element(getSFactory<T>().tag, nest: () {
      builder.attribute("hash", hash);
      creator(builder);
    });

    final frag = builder.buildDocument(); // build the document

    /// load the [SObject]
    return getSFactory<T>().load(kit, frag.rootElement);
  }

  FutureOr<void> Function(SKit kit) get beforeCreate => (kit) async {
        return;
      };

  /// Creator must never be asynchronous, as the xml package does not play nicely with it.
  /// It must be synchronous. However, if you need to use asyncronous code,
  /// use [beforeCreate] to do stuff before creating the [SObject].
  void Function(XmlBuilder builder) get creator;
}

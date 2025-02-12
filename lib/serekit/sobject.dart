import 'dart:async';

import 'package:arceus/serekit/serekit.dart';
import 'package:xml/xml.dart';

export 'package:xml/xml.dart';
export 'package:arceus/serekit/serekit.dart';

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
  /// Any and all [SReference]s will be resolved to their actual objects.
  /// So if a [SArchive] is needed, then if this method finds a [SRArchive], it will resolve it to a [SArchive].
  /// ```dart
  /// getChild<SArchive>(); // A [SRArchive] will be resolved to a SArchive and returned.
  /// ```
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
        if (!attributes.containsKey(attribute)) {
          throw ArgumentError(
              "Missing '$attribute'. Attributes needed: ${requiredAttributes.keys.join(", ")}");
        }
        final check =
            await requiredAttributes[attribute]!(attributes[attribute]);
        if (!check) {
          throw Exception("$attribute failed check!");
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
  /// is if there are essential attributes that need to be given before creating the xml node.
  /// If there are essential attributes, they should be in the [requiredAttributes] map.
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

/// A reference to another [SObject].
/// This is used when an object needs to reference another object that could be anywhere in the xml file.
abstract class SReference<T extends SObject> extends SObject {
  SReference(super.kit, super._node);
  FutureOr<T?> getRef();
}

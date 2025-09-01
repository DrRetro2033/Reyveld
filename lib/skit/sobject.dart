import 'dart:async';
import 'dart:convert';
import 'package:reyveld/skit/skit.dart';

export 'package:xml/xml.dart';
export 'package:reyveld/skit/skit.dart';
export 'package:reyveld/build_runner/annotations.dart';
export 'package:reyveld/scripting/lua.dart';
export 'package:reyveld/scripting/sinterface.dart';

part 'sroot.dart';
part 'sindent.dart';
part 'sfactory.dart';
part 'screator.dart';
part 'sobject.interface.dart';

/// This file consists of three core elements for both creating and loading [SObject]s:
/// - The [SObject] itself.
/// - The [SFactory] of the [SObject] used for loading.
/// - The [SCreator] of the [SObject] used for creating.
///
/// A object that wraps around a [XmlNode] and provides a simple API to access its attributes, children, and more.
/// SObjects must have a [SFactory] object inside [_sobjectFactories] (inside skit.factories.dart) in order to be parsed from xml properly.
/// If there is no [SFactory] object found, then the [GenericFactory] will be used, which is not recommended as it will not have strict,
/// predetermined behavior.
class SObject {
  final XmlElement _node;
  SKit? _kit;

  SKit get kit {
    if (_kit == null) {
      throw Exception(
          "SObject has no kit! Please make sure you've added the SObject to a kit before using it.");
    }
    return _kit!;
  }

  set kit(SKit? kit) {
    _kit = kit;
  }

  SObject(this._node);

  /// Sets an attribute of the xml node.
  /// Should be used in a setter method:
  /// ```dart
  /// set name(String value) => set("name", value);
  /// ```
  void set(String key, dynamic value) {
    if (value == null) {
      _node.removeAttribute(key);
    } else {
      _node.setAttribute(key, encodeText(value.toString()));
    }
  }

  /// Gets an attribute of the xml node.
  /// Should be used in a getter method:
  /// ```dart
  /// String get name => get("name");
  /// ```
  String? get(String key) {
    if (_node.getAttribute(key) == null) return null;
    return decodeText(_node.getAttribute(key)!);
  }

  /// Returns the parent of the xml node, if it has one.
  XmlNode? get _parent => _node.parent;

  bool get hasParent => _parent != null;

  /// Returns the inner text of the xml node.
  String? get innerText => _node.innerText;
  set innerText(String? value) => _node.innerText = value ?? "";
  String get tag => _node.localName;

  /// Checks if the xml node has an attribute.
  /// Should be used when checking if an attribute exists, if needed.
  bool has(String key) => _node.getAttribute(key) != null;

  /// Adds a child [SObject] to the xml node.
  /// Removes the child from its current parent to safely move it to the new parent.
  void addChild(SObject child) {
    if (child._parent != null) child._node.remove();
    if (child is SRoot) {
      throw Exception("Cannot add a SRoot to a SObject!");
    }
    child.kit = _kit;
    _node.children.add(child._node);
  }

  void addChildren(List<SObject?> children) {
    for (var child in children) {
      if (child!._parent != null) child._node.remove();
      if (child is SRoot) {
        throw Exception("Cannot add a SRoot to a SObject!");
      }
      child.kit = _kit;
      _node.children.add(child._node);
    }
  }

  /// Removes a child [SObject] from the xml node.
  void removeChild(SObject child) {
    if (_node.contains(child._node)) {
      child._node.remove();
    }
  }

  /// Removes the [SObject] from its current parent.
  void unparent() {
    _node.remove();
  }

  /// Returns a list of children of the [SObject], with the specific type.
  List<T?> getChildren<T extends SObject>() {
    List<T?> children = [];
    for (var child in _node.childElements) {
      final factory = getSFactory(child.name.local);
      if (factory is! SFactory<T>) continue;
      children.add(factory.load(child)..kit = _kit);
    }
    return children;
  }

  /// Returns a child of the [SObject], with the specific type.
  /// If [filter] is provided, it will only return the first child that matches the filter.
  T? getChild<T extends SObject>({bool Function(T)? filter}) {
    for (var child in _node.childElements) {
      final factory = getSFactory(child.name.local);
      if (factory is! SFactory<T>) {
        continue;
      }
      T obj = factory.load(child)..kit = _kit;
      if (filter != null && !filter(obj)) {
        continue;
      }
      return obj;
    }
    return null;
  }

  /// Returns the parent of the [SObject], if it has one.
  /// If [filter] is provided, it will only return the parent that matches the filter.
  T? getParent<T extends SObject>() {
    if (_node.parentElement == null) return null;
    final factory = getSFactory(_node.parentElement!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(_node.parentElement!)..kit = _kit;
    return obj;
  }

  /// Returns a list of descendants of the [SObject], with the specific type.
  List<T?> getDescendants<T extends SObject>({bool Function(T)? filter}) {
    List<T?> descendants = [];
    for (var child in _node.descendantElements) {
      final factory = getSFactory(child.name.local);
      if (factory is! SFactory<T>) continue;
      T obj = factory.load(child)..kit = _kit;
      if (filter != null && !filter(obj)) {
        continue;
      }
      descendants.add(obj);
    }
    // sort descendants by depth, with the deepest last.
    descendants.sort((a, b) => a!.getDepth().compareTo(b!.getDepth()));
    return descendants;
  }

  /// Returns the ancestors of the [SObject], if it has one.
  List<T?> getAncestors<T extends SObject>({bool Function(T)? filter}) {
    final ancest = <T>[];
    Iterable<XmlElement> ancestors = _node.ancestorElements;
    for (var ancestor in ancestors) {
      final factory = getSFactory(ancestor.name.local);
      if (factory is! SFactory<T>) continue;
      T obj = factory.load(ancestor)..kit = _kit;
      if (filter != null && !filter(obj)) {
        continue;
      }
      ancest.add(obj);
    }
    return ancest;
  }

  /// Returns the sibling of the [SObject] above it, if it has one.
  T? getSiblingAbove<T extends SObject>({bool Function(T)? filter}) {
    if (_node.previousElementSibling == null) return null;
    final factory = getSFactory(_node.previousElementSibling!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(_node.previousElementSibling!)..kit = _kit;
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns the sibling of the [SObject] below it, if it has one.
  T? getSiblingBelow<T extends SObject>({bool Function(T)? filter}) {
    if (_node.nextElementSibling == null) return null;
    final factory = getSFactory(_node.nextElementSibling!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(_node.nextElementSibling!)..kit = _kit;
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns the depth of the [SObject] relative to its root.
  int getDepth() {
    return _node.depth;
  }

  /// Returns the [SObject] as a xml String.
  String toXmlString() => _node.toXmlString(pretty: true, newLine: "\n");

  /// Returns the [SObject] as a json map.
  /// This is used to serialize the [SObject] for sending to clients.
  Map<String, dynamic> toJson() => {
        tag: {
          ..._attrbutesToJson(),
          "children": getChildren().map((child) => child!.toJson()).toList(),
        }
      };

  /// Returns a map of the attributes of the xml node.
  /// This is used in [toJson].
  Map<String, String> _attrbutesToJson() => Map.fromEntries(_node.attributes
      .map((attr) => MapEntry(attr.name.local, decodeText(attr.value))));

  /// Creates a copy of the [SObject].
  SObject copy() {
    final factory = getSFactory(_node.name.local);
    return factory.load(_node.copy())..kit = _kit;
  }

  void onSave(SKit kit) {
    for (var child in getChildren()) {
      child!.onSave(kit);
    }
  }

  @override
  int get hashCode => _node.hashCode;

  @override
  operator ==(Object other) =>
      other is SObject &&
      (identical(other._node, _node) ||
          other._node == _node ||
          other._node.isEqualNode(_node));
}

String encodeText(String text) {
  return base64.encode(utf8.encode(text));
}

String decodeText(String text) {
  return utf8.decode(base64.decode(text));
}

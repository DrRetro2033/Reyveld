import 'dart:async';
import 'package:arceus/skit/skit.dart';
import 'package:arceus/uuid.dart';

export 'package:xml/xml.dart';
export 'package:arceus/skit/skit.dart';
export 'package:arceus/build_runner/annotations.dart';
export 'package:arceus/scripting/lua.dart';
export 'package:arceus/scripting/sinterface.dart';

part 'sroot.dart';
part 'sindent.dart';

/// This file consists of three core elements for both creating and loading [SObject]s:
/// - The [SObject] itself.
/// - The [SFactory] of the [SObject] used for loading.
/// - The [SCreator] of the [SObject] used for creating.
///
/// A object that wraps around a [XmlNode] and provides a simple API to access its attributes, children, and more.
/// SObjects must have a [SFactory] object inside [_sobjectFactories] (inside serekit.g.dart) in order to be parsed from xml properly.
/// If there is no [SFactory] object found, then the [GenericFactory] will be used, which is not recommended as it will not have strict,
/// predetermined behavior.
class SObject {
  final XmlNode _node;
  final SKit kit;

  SObject(this.kit, this._node);

  /// Sets an attribute of the xml node.
  /// Should be used in a setter method:
  /// ```dart
  /// set name(String value) => set("name", value);
  /// ```
  void set(String key, dynamic value) {
    _node.setAttribute(key, value.toString());
  }

  /// Gets an attribute of the xml node.
  /// Should be used in a getter method:
  /// ```dart
  /// String get name => get("name");
  /// ```
  String? get(String key) {
    if (_node.getAttribute(key) == null) return null;
    return _node.getAttribute(key)!;
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
    if (child is SRoot) {
      throw Exception("Cannot add a SRoot to a SObject!");
    }
    _node.children.add(child._node);
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
      children.add(factory.load(kit, child));
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
      T obj = factory.load(kit, child);
      if (filter != null && !filter(obj)) {
        continue;
      }
      return obj;
    }
    return null;
  }

  /// Returns the parent of the [SObject], if it has one.
  /// If [filter] is provided, it will only return the parent that matches the filter.
  T? getParent<T extends SObject>({bool Function(T)? filter}) {
    if (_node.parentElement == null) return null;
    final factory = getSFactory(_node.parentElement!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(kit, _node.parentElement!);
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns a list of descendants of the [SObject], with the specific type.
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

  /// Returns the closest ancestor of the [SObject], if it has one.
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

  /// Returns the sibling of the [SObject] above it, if it has one.
  T? getSiblingAbove<T extends SObject>({bool Function(T)? filter}) {
    if (_node.previousElementSibling == null) return null;
    final factory = getSFactory(_node.previousElementSibling!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(kit, _node.previousElementSibling!);
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns the sibling of the [SObject] below it, if it has one.
  T? getSiblingBelow<T extends SObject>({bool Function(T)? filter}) {
    if (_node.nextElementSibling == null) return null;
    final factory = getSFactory(_node.nextElementSibling!.name.local);
    if (factory is! SFactory<T>) return null;
    T obj = factory.load(kit, _node.nextElementSibling!);
    if (filter != null && !filter(obj)) return null;
    return obj;
  }

  /// Returns the depth of the [SObject] relative to its root.
  int getDepth() {
    return _node.depth;
  }

  /// Returns the [SObject] as a xml String.
  String toXmlString() => _node.toXmlString(pretty: true, newLine: "\n");
}

/// A base factory for parsing [SObject]s from xml.
/// Subclasses should be created as follows:
/// ```dart
/// class MySFactory extends SFactory<MySObject> {
///   ...
/// }
/// ```
abstract class SFactory<T extends SObject> {
  /// The tag of the associated xml node.
  /// Will be checked if unique in [_sobjectFactories] in serekit.factories.dart.
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

/// A base creator for creating [SObject]s.
/// Creation was at first delegated to [SFactory], however
/// it was moved to its own base class for more stricter
/// control over the creation process.
///
/// All subclasses should implement the [creator] method.
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
///
/// Future<SObject> createObj(SKit kit) async {
///   return await MySCreator("Hello").create(kit);
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

/// The interface for [SObject]
// abstract class SObjectInterface<T extends SObject> extends SInterface<T> {
//   @override
//   Map<String, dynamic> toMap() => {
//         "addChild": (Lua state) async {
//           final child = await state.getFromTop<SObject>();
//           object!.addChild(child);
//         },
//         "removeChild": (Lua state) async {
//           final child = await state.getFromTop<SObject>();
//           object!.removeChild(child);
//         },
//         "getChild": (Lua state) async {
//           final table = await state.getFromTop<Map<String, dynamic>>();
//           final type = table.containsKey("class") ? table["class"] : null;
//           final attributes = table.containsKey("attrb")
//               ? table["attrb"] as Map<String, dynamic>
//               : <String, dynamic>{};
//           return object!.getChild<SObject>(
//             filter: (e) {
//               if (type != null) {
//                 if (Lua.getInterface(e)?.className != type) {
//                   return false;
//                 }
//               }
//               for (final key in attributes.keys) {
//                 if (e.get(key) != attributes[key]) {
//                   return false;
//                 }
//               }
//               return true;
//             },
//           );
//         },
//         "getChildren": () async {
//           return object!.getChildren<SObject>();
//         },
//         "getParent": () async {
//           return object!.getParent<SObject>();
//         },
//         "getDescendants": () async {
//           return object!.getDescendants<SObject>();
//         },
//         "getAncestors": () async {
//           return object!.getAncestors<SObject>();
//         },
//         "getSiblingAbove": () async {
//           return object!.getSiblingAbove<SObject>();
//         },
//         "getSiblingBelow": () async {
//           return object!.getSiblingBelow<SObject>();
//         },
//         ...exports
//       };
// }

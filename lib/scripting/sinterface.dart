import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobject.dart';

/// This is a typedef for a lua entrypoint.
/// A entrypoint is a function with a description, arguments, and return type.
/// The arguments are a list of tuples of (description, type, isOptional).
typedef LuaEntrypoint = (
  String, // description
  Map<String, LuaArgument>, // arguments <name, (description, type, isOptional)>
  Type?, // return type or null
  Function // function
);

typedef LuaArgument = (String, {Type type, bool isRequired});

/// This acts as an interface between Lua and SKits.
abstract class SInterface<T> {
  /// This is the name of the interface.
  String get className;

  /// This is the description of the interface.
  String get description;

  /// This converts the interface into a Lua table.
  Map<String, dynamic> toLua(Lua state, String luaHash) {
    return {
      "class": className,
      "objHash": luaHash,
      "toString": (Lua state) {
        return toString();
      },
      ...allExports
    };
  }

  /// This is the object that this interface wraps around.
  /// This will not be pushed to the stack, and instead
  /// [statics] and [exports] will be used.
  T? object;

  /// These are the methods of the interface that will be pushed as a table
  /// to Lua when pushing a object of type [T] to the stack.
  Map<String, LuaEntrypoint> get exports => {};

  /// This is a combination of [exports] and [parent] exports.
  /// Used in [toLua].
  Map<String, LuaEntrypoint> get allExports {
    final map = exports;
    if (parent != null && parent!.runtimeType != runtimeType) {
      for (final entry in parent!.allExports.entries) {
        map.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return map;
  }

  /// This is the static methods of the interface.
  /// This will be added to a global Lua table with the same name as the interface.
  /// Used for constructors.
  Map<String, LuaEntrypoint> get statics => {};

  /// This is the parent interface of this interface.
  /// If this interface does not have a parent, then this will be null.
  /// Used when pushing a object to the stack, and when generating docs.
  SInterface? get parent => null;

  @override
  String toString() => object.toString();

  /// This checks if an object is of type [T].
  bool isType(Object object) {
    return object is T;
  }

  /// This generates the docs for the interface.
  Future<void> generateDocs() async {
    final doc = File(
        "${Arceus.appDataPath}/docs/${Arceus.currentVersion.toString()}/${className.toLowerCase()}.lua");
    await doc.create(recursive: true);
    await doc.writeAsString("""
---@meta _

${statics.isNotEmpty ? _luaStatics() : ""}
${_luaExports()}
""");
  }

  /// This generates the static, global table for the interface.
  String _luaStatics() => """
$className = {}

${statics.entries.map((e) => _luaMethod(e)).join("\n")}
""";

  /// This generates the methods for the interface.
  String _luaExports() {
    final text = StringBuffer();
    text.writeln(
        "---@class $className${parent != null && parent!.className != className ? ": ${parent!.className}" : ""}");
    for (final line in description.split("\n")) {
      if (line.isEmpty) continue;
      text.writeln("---$line");
    }
    text.writeln("local $className = {}");
    for (final export in exports.entries) {
      text.writeln(_luaMethod(export));
    }
    return text.toString();
  }

  String _luaMethod(MapEntry<String, LuaEntrypoint> export) {
    StringBuffer method = StringBuffer();
    if (export.value.$2.isNotEmpty) {
      for (final arg in export.value.$2.entries) {
        method.writeln(
            "---@param ${arg.key} ${_convertDartToLua(arg.value.type) + (arg.value.isRequired ? "" : "?")} ${arg.value.$1}");
      }
    }
    if (export.value.$3 != null) {
      method.writeln("---@return ${_convertDartToLua(export.value.$3!)}");
    }
    for (final line in export.value.$1.split("\n")) {
      if (line.isEmpty) continue;
      method.writeln("---$line");
    }
    method.writeln(
        "function $className.${export.key}(${export.value.$2.keys.join(", ")}) end");
    return method.toString();
  }

  String _convertDartToLua(Type type) {
    if (type == String) {
      return "string";
    } else if (type == int) {
      return "integer";
    } else if (type == bool) {
      return "boolean";
    } else if (type == double) {
      return "number";
    } else if (type == List) {
      return "List";
    } else if (type == Map) {
      return "table";
    } else if (type == Object) {
      return "any";
    } else {
      return type.toString();
    }
  }
}

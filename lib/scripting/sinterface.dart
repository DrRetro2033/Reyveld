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

  String? get extras => null;

  /// This converts the interface into a Map.
  Map<String, dynamic> toMap() => {...exports};

  /// This converts the interface into a Lua table.
  Map<String, dynamic> toLua(Lua state, String luaHash) {
    return {
      "class": className,
      "objHash": luaHash,
      "toString": (Lua state) {
        return toString();
      },
      ...toMap(),
    };
  }

  T? object;
  Map<String, LuaEntrypoint> get exports => {};

  /// This is the static methods of the interface.
  /// This will be added to a global Lua table with the same name as the interface.
  /// Used for constructors.
  Map<String, LuaEntrypoint> get statics => {};

  @override
  String toString() => object.toString();

  bool isType(Object object) {
    return object is T;
  }

  Future<void> generateDocs() async {
    final doc = File(
        "${Arceus.appDataPath}/docs/${Arceus.currentVersion.toString()}/${className.toLowerCase()}.lua");
    await doc.create(recursive: true);
    await doc.writeAsString("""
---@meta _

${extras ?? ""}
${statics.isNotEmpty ? _luaStatics() : ""}
${_luaExports()}
""");
  }

  String _luaStatics() => """
$className = {}

${statics.entries.map((e) => _luaMethod(e)).join("\n")}
""";

  String _luaExports() {
    final text = StringBuffer();
    text.writeln("---@class $className");
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
    } else {
      return type.toString();
    }
  }
}

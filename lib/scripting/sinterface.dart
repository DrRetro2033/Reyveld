import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobject.dart';

typedef LuaEntrypoint = (
  String,
  Map<String, (String, Type, bool)>,
  Type?,
  dynamic Function(Lua)
);

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
            "---@param ${arg.key} ${_convertDartToLua(arg.value.$2) + (arg.value.$3 ? "" : "?")} ${arg.value.$1}");
      }
    }
    if (export.value.$3 != null) {
      method.writeln("---@return ${_convertDartToLua(export.value.$3!)}");
    }
    method.writeln("---${export.value.$1}");
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

/// The interface for [SObject]
abstract class SObjectInterface<T extends SObject> extends SInterface<T> {
  @override
  Map<String, dynamic> toMap() => {
        "addChild": (Lua state) async {
          final child = await state.getFromTop<SObject>();
          object!.addChild(child);
        },
        "removeChild": (Lua state) async {
          final child = await state.getFromTop<SObject>();
          object!.removeChild(child);
        },
        "getChild": (Lua state) async {
          final table = await state.getFromTop<Map<String, dynamic>>();
          final type = table.containsKey("class") ? table["class"] : null;
          final attributes = table.containsKey("attrb")
              ? table["attrb"] as Map<String, dynamic>
              : <String, dynamic>{};
          return object!.getChild<SObject>(
            filter: (e) {
              if (type != null) {
                if (Lua.getInterface(e)?.className != type) {
                  return false;
                }
              }
              for (final key in attributes.keys) {
                if (e.get(key) != attributes[key]) {
                  return false;
                }
              }
              return true;
            },
          );
        },
        "getChildren": (_) async {
          return object!.getChildren<SObject>();
        },
        "getParent": (_) async {
          return object!.getParent<SObject>();
        },
        "getDescendants": (_) async {
          return object!.getDescendants<SObject>();
        },
        "getAncestors": (_) async {
          return object!.getAncestors<SObject>();
        },
        "getSiblingAbove": (_) async {
          return object!.getSiblingAbove<SObject>();
        },
        "getSiblingBelow": (_) async {
          return object!.getSiblingBelow<SObject>();
        },
        ...exports
      };
}

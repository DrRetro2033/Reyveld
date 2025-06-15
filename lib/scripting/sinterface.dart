import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobject.dart';

/// An export for Lua.
/// An export is a function or field for a [SInterface].
abstract class LExport {
  final String name;
  final String descr;
  const LExport({required this.name, this.descr = ""});
}

/// This is a lua entrypoint.
/// A entrypoint is a function with a description, arguments, and return type.
class LEntry extends LExport {
  /// The arguments of the entrypoint.
  final Map<String, LArg> args;

  /// This is used to define if the entrypoint is async.
  final bool isAsync;

  /// The return type of the entrypoint.
  /// This is used to define the return type of the entrypoint.
  final Type? returnType;

  final bool returnGeneric;

  /// This is used to determine if the entrypoint has named arguments.
  /// Named arguments are arguments that are accessed by name by adding a table
  /// to the end of the argument list.
  bool get hasNamedArgs => args.entries.any((e) => !e.value.positional);

  /// This is used to determine the number of positional arguments.
  /// Used to determine if the named arguments table is provided.
  int get numOfPositionalArgs =>
      args.entries.where((e) => e.value.positional).length;

  /// The actual function of the entrypoint.
  final Function func;

  const LEntry(this.func,
      {required super.name,
      super.descr,
      this.args = const {},
      this.isAsync = false,
      this.returnType,
      this.returnGeneric = false});
}

/// This is a lua argument.
final class LArg<T> {
  final String descr;

  /// By default, this argument is required.
  final bool required;

  /// If true, the argument is positional.
  /// If false, the argument is named, and can be accessed by name by adding a table to the end of the argument list.
  /// By default, it is true.
  ///
  /// Note: If a named argument is provided, then DO NOT use optional positional arguments as they WILL BREAK THINGS IN UNEXPECTED WAYS.
  final bool positional;

  /// Set this to override the doc type of the argument.
  /// You can use this to have a more specific type than the default one.
  /// For example:
  /// ```lua
  /// ---@param addfunc fun(a: int, b: int):int  Do this to specify the return and parmeters of a function parameter
  /// ```
  final String? docTypeOverride;

  /// This is the type of the argument.
  Type get type => T;

  const LArg(
      {this.descr = "",
      this.required = true,
      this.positional = true,
      this.docTypeOverride});

  /// This is a helper function to check if a value is of type [T].
  /// If it is, it returns the value, otherwise it returns null.
  /// It is used to check if the argument is of the correct type.
  T? cast(dynamic value) => typeCheck<T>(value);
}

/// This is a lua field.
class LField<T> extends LExport {
  final dynamic value;
  Type get type => T;
  const LField(this.value, {required super.name, super.descr});
}

/// This is a helper function to check if a value is of type [T].
/// If it is, it returns the value, otherwise it returns null.
T? typeCheck<T>(dynamic value) {
  if (value is T) {
    // Arceus.talker.info("Type check passed: $T -> $value");
    return value;
  }
  return null;
}

/// This acts as an interface between Lua and Arceus.
abstract class SInterface<T> {
  /// This is the name of the interface.
  String get className;

  String get staticDescription => classDescription;

  /// This is the description of the object interface.
  /// By default, [staticDescription] shares the same description as this.
  String get classDescription => "";

  /// This converts the interface into a Lua table.
  Map<String, dynamic> toLua(Lua state, String luaHash) {
    Map<String, LExport> exportTable = {};
    for (final export in allExports) {
      exportTable[export.name] = export;
    }
    return {"class": className, "objHash": luaHash, ...exportTable};
  }

  /// This is the object that this interface wraps around.
  /// This will not be pushed to the stack, and instead
  /// [statics] and [exports] will be used.
  T? object;

  /// These are the methods of the interface that will be pushed as a table
  /// to Lua when pushing a object of type [T] to the stack.
  Set<LExport> get exports => {};

  /// This is a combination of [exports] and [parent] exports.
  /// Used in [toLua].
  Set<LExport> get allExports {
    /// Initialize the map with the current exports.
    final map = exports;

    /// If there is no parent, then return the map.
    if (parent == null) return map;

    /// If there is a parent, then set the parent interface's object to the current object.
    final parentInstance = parent!..object = object;

    /// Add the parent's exports to the map.
    for (final entry in parentInstance.allExports) {
      map.add(entry);
    }
    return map;
  }

  /// This is the static methods of the interface.
  /// This will be added to a global Lua table with the same name as the interface.
  /// Used for constructors.
  Set<LEntry> get statics => {};

  /// Used to push statics as a global table.
  Map<String, LEntry> get staticTable {
    final map = <String, LEntry>{};
    for (final entry in statics) {
      map[entry.name] = entry;
    }
    return map;
  }

  /// This is the parent interface of this interface.
  /// If this interface does not have a parent, then this will be null.
  /// Used when pushing a object to the stack, and when generating docs.
  SInterface? get parent => null;

  /// This is the priority of the interface.
  /// The priority is determined by the number of parents the interface has.
  /// The higher the priority, the more specific the interface is, which in turn
  /// means that it should have a higher priority than its parents.
  int get priority => parent == null ? 0 : parent!.priority + 1;

  @override
  String toString() => object.toString();

  /// This is used when pushing a object to the stack.
  /// Used to figure out which interface to use if it matches the type of the object.
  bool isType(dynamic object) => typeCheck<T>(object) != null;

  /// This generates the docs for the interface.
  Future<void> generateDocs() async {
    final doc = File(
        "${Arceus.appDataPath}/docs/${Arceus.currentVersion.toString()}/${className.toLowerCase()}.lua");
    await doc.create(recursive: true);
    await doc.writeAsString("""
---@meta _
${_sources()}

${statics.isNotEmpty ? _luaStatics() : ""}
${allExports.isNotEmpty || parent != null ? _luaExports() : ""}
""");
  }

  /// This generates the static, global table for the interface.
  String _luaStatics() => """
${_covertDescriptionToComment(staticDescription)}
$className = {}

${statics.whereType<LField>().map(_luaField).join("\n")}
${statics.whereType<LEntry>().map(_luaMethod).join("\n")}
""";

  String _sources() {
    return parent == null
        ? ""
        : "---@source ${parent!.className.toLowerCase()}.lua";
  }

  /// This generates the methods for the interface.
  String _luaExports() {
    final text = StringBuffer();
    text.writeln(
        "---@class $className${parent != null && parent!.className != className ? ": ${parent!.className}" : ""}");
    for (final export in allExports.whereType<LField>()) {
      text.writeln(_luaField(export));
    }
    if (classDescription.isNotEmpty) {
      text.writeln(_covertDescriptionToComment(classDescription));
    }

    text.writeln("local $className = {}");

    for (final export in allExports.whereType<LEntry>()) {
      text.writeln(_luaMethod(export));
    }
    return text.toString();
  }

  /// This converts a description into a comment for lua.
  String _covertDescriptionToComment(String description) {
    final text = StringBuffer();
    for (final line in description.split("\n")) {
      if (line.isEmpty) continue;
      text.writeln("---$line");
    }
    return text.toString().trim();
  }

  /// This generates a lua field.
  String _luaField(LField export) {
    final field =
        "---@field ${export.name} ${_convertDartToLua(export.type)} ${export.descr}";
    // Arceus.talker.debug(field);
    return field;
  }

  /// This generates a single method in the docs for the interface.
  /// This will generate a function with the name ([LEntry.name]),
  /// and the arguments ([LEntry.args]),
  /// and return type ([LEntry.returnType]);
  /// Plus the description ([LEntry.descr]).
  String _luaMethod(LEntry export) {
    StringBuffer method = StringBuffer();
    if (export.returnGeneric && export.returnType != null) {
      method
          .writeln("---@generic T : ${_convertDartToLua(export.returnType!)}");
    }
    if (export.args.isNotEmpty) {
      for (final arg in export.args.entries) {
        if (arg.value.positional) {
          method.writeln(
              "---@param ${arg.key} ${(arg.value.docTypeOverride ?? _convertDartToLua(arg.value.type)) + (arg.value.required ? "" : "?")} ${arg.value.descr}");
        }
        // Document the argument
      }
      if (export.hasNamedArgs) {
        // Document the named arguments
        method.writeln(
            "---@param named table? Named arguments go here. See description below for more info.");
      }
    }
    if (export.returnGeneric && export.returnType != null) {
      method.writeln("---@return T");
    } else if (export.returnType != null) {
      // Document the return type
      method.writeln("---@return ${_convertDartToLua(export.returnType!)}");
    }
    if (export.isAsync) {
      method.writeln("---@async");
    }
    for (final line in export.descr.split("\n")) {
      // if (line.isEmpty) continue;
      method.writeln("---$line");
    }
    if (export.hasNamedArgs) {
      method.writeln("---");
      method.writeln("--- Named arguments:");
      for (final arg in export.args.entries.where((e) => !e.value.positional)) {
        method.writeln("---");
        method.writeln(
            "--- \t`${arg.key}`: ${_convertDartToLua(arg.value.type)}${arg.value.required ? "" : "?"} - ${arg.value.descr}");
      }
    }
    method.writeln("function $className.${export.name}(${[
      ...export.args.entries.where((e) => e.value.positional).map((e) => e.key),
      export.hasNamedArgs ? "named" : null
    ].whereType<String>().join(", ")}) end");
    return method.toString();
  }

  /// This converts a native dart type into a lua type.
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
    } else if (type == LuaFuncRef) {
      return "function";
    } else {
      // Try and find a interface for the type and use that.
      final inter_ = Lua.getInterfaceFromType(type);
      if (inter_ != null) {
        return inter_.className;
      }
      // If not, throw an exception as we don't know how to handle this type.
      throw Exception("Don't know how to handle type $type");
    }
  }

  bool equalsType(Type type) => type == T;

  @override
  int get hashCode => className.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SInterface && other.className == className;
}

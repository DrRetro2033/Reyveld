import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/scripting/list.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/constellation/constellation.dart';
import 'package:arceus/version_control/star/star.dart';
import 'package:lua_dardo_async/lua.dart';
import '../skit/skit.dart';

/// The main class for running lua scripts.
class Lua {
  final LuaState state;

  final Stopwatch stopwatch = Stopwatch();

  Lua() : state = LuaState.newState();

  final Map<String, SInterface> _objects = {};

  static Set<SInterface> get interfaces => {
        ArceusInterface(),
        ListInterface(),
        SHeaderInterface(),
        SObjectInterface(),
        SKitInterface(),
        ConstellationInterface(),
        StarInterface(),
        SArchiveInterface(),
        SFileInterface(),
        SRFileInterface(),
        SLibraryInterface(),
      };

  static Map<String, List<Enum>> get enums => {
        "SKitType": SKitType.values,
      };

  Future<void> init() async {
    await state.openLibs();

    for (final enum_ in enums.entries) {
      final table = <String, dynamic>{};
      for (final value in enum_.value) {
        table[value.name] = value.index;
      }
      await addGlobal(enum_.key, table);
    }

    for (final interface_ in interfaces) {
      if (interface_.statics.isNotEmpty) {
        await addGlobal(interface_.className, interface_.allStatics);
      }
    }
  }

  /// Formats a single stack item for logging.
  /// It includes the index, type, and value.
  String _formatStackItem(int i, LuaType type, [String? value]) {
    var msg = "index:$i -> $type";
    if (value != null) msg += " value:$value";
    return msg;
  }

  /// Formats the entire stack for logging.
  String _formatStack() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln(">------  stack  top  ------<");
    var len = state.getTop();
    for (int i = len; i >= 1; i--) {
      LuaType t = state.type(i);
      switch (state.type(i)) {
        case LuaType.luaNone:
          buffer.writeln(_formatStackItem(i, t));
          break;

        case LuaType.luaNil:
          buffer.writeln(_formatStackItem(i, t));
          break;

        case LuaType.luaBoolean:
          buffer.writeln(
              _formatStackItem(i, t, state.toBoolean(i) ? "true" : "false"));
          break;

        case LuaType.luaLightUserdata:
          buffer.writeln(_formatStackItem(i, t));
          break;

        case LuaType.luaNumber:
          if (state.isInteger(i)) {
            buffer.writeln(
                _formatStackItem(i, t, "(integer)${state.toInteger(i)}"));
          } else if (state.isNumber(i)) {
            buffer.writeln(_formatStackItem(i, t, "${state.toNumber(i)}"));
          }
          break;

        case LuaType.luaString:
          buffer.writeln(_formatStackItem(i, t, "${state.toStr(i)}"));
          break;

        case LuaType.luaTable:
          buffer.writeln(_formatStackItem(i, t));
          break;

        case LuaType.luaFunction:
          buffer.writeln(_formatStackItem(i, t));
          break;

        case LuaType.luaUserdata:
          buffer.writeln(_formatStackItem(i, t));
          break;

        case LuaType.luaThread:
          buffer.writeln(_formatStackItem(i, t));
          break;
      }
    }
    buffer.writeln(">------ stack bottom ------<");
    return buffer.toString();
  }

  /// Adds a global to the Lua state.
  ///
  /// [name] is the name of the global.
  ///
  /// [table] is the table to add as the global.
  ///
  /// This will push the table to the stack and then set the global with the given name.
  Future<void> addGlobal(String name, dynamic table) async {
    await _pushToStack(table);
    await state.setGlobal(name);
  }

  /// Pushes a value to the stack.
  Future<void> _pushToStack(dynamic value) async {
    if (value is String) {
      state.pushString(value);
    } else if (value is int) {
      state.pushInteger(value);
    } else if (value is bool) {
      state.pushBoolean(value);
    } else if (value is double) {
      state.pushNumber(value);
    } else if (value is Map<String, dynamic>) {
      state.newTable();
      for (String key in value.keys) {
        await _pushToStack(key);
        await _pushToStack(value[key]);
        await state.setTable(state.getTop() - 2);
      }
    } else if (value is Object && getInterface(value) != null) {
      final interface_ = getInterface(value)!..object = value;
      final hash = _createUniqueObjectHash();
      _objects[hash] = interface_;
      await _pushToStack(interface_.toLua(this, hash));
    } else if (value is FutureOr<dynamic> Function(Lua)) {
      state.pushDartFunction((state) async {
        await _pushToStack(await value(this));
        return 1;
      });
    } else if (value is LuaEntrypoint) {
      state.pushDartFunction((state) async {
        try {
          List<dynamic> args = [];
          final stack = _formatStack();
          for (final arg in value.$2.entries.toList().reversed) {
            final argValue = getFromTop(pop: false);
            // Attempt to cast the argument to the expected type.
            // It will return null if the cast fails.
            final trueValue = arg.value.cast(argValue);
            if (trueValue == null) {
              if (!arg.value.isRequired) {
                continue;
              } else {
                // Report the before and after stack and throw an error.
                Arceus.talker.error("Before:\n$stack");
                Arceus.talker.error("After:\n${_formatStack()}");
                throw Exception(
                    "Expected ${arg.value.type} but got ${argValue.runtimeType}");
              }
            }
            args.add(trueValue);
            state.pop(1);
          }
          final finalArgs = args.reversed.toList()
            ..removeWhere((e) => e == null);

          // Log the arguments for debugging.
          Arceus.talker.debug("Args: $finalArgs");
          Arceus.talker.debug("Before:\n$stack");
          Arceus.talker.debug("After:\n${_formatStack()}");
          if (value.$3 == null) {
            // Means that the function doesn't return anything, so just call it.
            await Function.apply(value.$5, finalArgs);
          } else {
            // Means that the function returns something, so call it and push the result to the stack.
            final result = await Function.apply(value.$5, finalArgs);
            await _pushToStack(result);
          }
          return 1;
        } catch (e, st) {
          Arceus.talker.error("", e, st);
          rethrow;
        }
      });
    } else {
      Arceus.talker.error("Could not push to stack: $value");
    }
  }

  /// Gets a value from the top of the stack.
  T? getFromTop<T>({bool pop = true}) {
    dynamic result;
    try {
      if (state.isString(state.getTop())) {
        result = state.toStr(state.getTop());
        if (T != String) {
          try {
            result = int.parse(result);
          } catch (e) {
            result = result;
          }
        }
      } else if (state.isInteger(state.getTop())) {
        result = state.toInteger(state.getTop());
      } else if (state.isNumber(state.getTop())) {
        result = state.toNumber(state.getTop());
      } else if (state.isBoolean(state.getTop())) {
        result = state.toBoolean(state.getTop());
      } else if (state.isTable(state.getTop())) {
        final table = _getTableFromState();
        if (table.containsKey("objHash") &&
            _objects[table["objHash"]] != null) {
          result = _objects[table["objHash"]]!.object;
        } else if (table.keys.every((e) => int.tryParse(e) != null)) {
          List<dynamic> list = [];
          for (final key in table.keys.toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)))) {
            list.add(table[key]);
          }
          result = list;
        } else {
          result = table;
        }
      } else if (state.isNoneOrNil(state.getTop())) {
        result = null;
      } else {
        result = null;
      }
    } catch (e, st) {
      Arceus.talker.error(e, st);
    }

    if (pop) {
      if (state.getTop() != 0) {
        state.pop(1);
      }
    }
    return result;
  }

  /// Creates a unique hash for an object.
  String _createUniqueObjectHash() => generateUniqueHash(_objects.keys.toSet());

  /// Returns a table from the lua state.
  Map<dynamic, dynamic> _getTableFromState() {
    Map<dynamic, dynamic> resultTable = {};
    state.pushNil();
    while (state.next(state.getTop() - 1)) {
      dynamic value = getFromTop();
      String key = getFromTop<String>()!;
      resultTable[key] = value;
      _pushToStack(key);
    }
    return resultTable;
  }

  // Compiles a lua project.
  Future<String> _compile(String entrypoint) async {
    final hexExp = RegExp(r"0x([0-9A-f]+)");
    final requireExp = RegExp(r"require ([A-z]+)");

    String compiled = entrypoint;

    while (requireExp.hasMatch(compiled)) {
      final match = requireExp.firstMatch(compiled)!;
      // Gets the library from the name.
      final lib = LuaLibrary("${Arceus.libraryPath}/${match.group(1)!}.skit");
      compiled = compiled.replaceRange(match.start, match.end, await lib.code);
    }

    while (hexExp.hasMatch(compiled)) {
      final match = hexExp.firstMatch(compiled)!;
      compiled = compiled.replaceRange(match.start, match.end,
          int.parse(match.group(1)!, radix: 16).toString());
    }
    return compiled;
  }

  Future<bool> awaitForCompletion() async {
    while (stopwatch.isRunning) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    return true;
  }

  // Runs a lua script.
  Future<dynamic> run(String entrypoint) async {
    /// Resets the stopwatch and starts it, to track process time,
    /// and to notify if its done.
    stopwatch.reset();
    stopwatch.start();

    /// Run the lua code and see if it was successful
    final successful = await state
        .doString(await _compile(entrypoint).then((value) => value.trim()));

    if (!successful) {
      /// If it wasn't successful, print the error and return null
      state.error();
      return null;
    }
    final result = getFromTop();
    stopwatch.stop();
    Arceus.talker
        .info("Lua result in ${stopwatch.elapsedMilliseconds}ms: $result");
    return result;
  }

  // Gets the interface for an object.
  static SInterface? getInterface(Object object) {
    for (final interface_ in interfaces) {
      if (interface_.isType(object)) {
        // Arceus.talker
        //     .debug("Found interface for $object (${interface_.runtimeType})");
        return interface_;
      }
    }
    return null;
  }

  // Generates a docs file for all of the interfaces.
  static Future<void> generateDocs() async {
    final dir = Directory(
        "${Arceus.appDataPath}/docs/${Arceus.currentVersion.toString()}");
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    for (final interface_ in interfaces) {
      await interface_.generateDocs();
    }
    _generateEnumDocs();
  }

  // Generates a docs file for all of the enums.
  static Future<void> _generateEnumDocs() async {
    final doc = File(
        "${Arceus.appDataPath}/docs/${Arceus.currentVersion.toString()}/enums.lua");
    await doc.create(recursive: true);
    await doc.writeAsString("""
---@meta _

${_formatEnums()}
""");
  }

  // Formats all of the enums for the docs file.
  static String _formatEnums() {
    List<String> formattedEnums = [];
    for (final enum_ in enums.entries) {
      formattedEnums.add("""
---@enum ${enum_.key}
${enum_.key} = {
  ${enum_.value.map((e) => "${e.name} = ${e.index},").join("\n  ")}
}
""");
    }
    return formattedEnums.join("\n\n");
  }
}

abstract class LuaCode {
  final String path;
  Future<String> get code;

  LuaCode(this.path);
}

class LuaScript extends LuaCode {
  @override
  get code async {
    final file = File(path);
    return await file.readAsString();
  }

  LuaScript(super.path);
}

class LuaLibrary extends LuaCode {
  LuaLibrary(super.path);

  @override
  get code async {
    final skit = await SKit.open(path, type: SKitType.library);
    final header = await skit.getHeader();
    return header!.getChild<SLibrary>()!.archive.then((archive) =>
        archive.getFiles().map((e) async => await e!.str).join("\n"));
  }
}

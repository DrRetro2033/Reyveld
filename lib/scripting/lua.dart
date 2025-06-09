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

  /// A map of all objects in the lua state.
  ///
  /// When pushing a object to the stack, an unique hash is generated and
  /// a duplicate of the SInterface with the object as its value is added to this map.
  final Map<String, SInterface> _objects = {};

  /// A set of all interfaces in the lua state.
  static Set<SInterface> get _interfaces => {
        ArceusInterface(),
        SObjectListInterface(),
        ListInterface(),
        SHeaderInterface(),
        SKitInterface(),
        ConstellationInterface(),
        StarInterface(),
        SArchiveInterface(),
        SFileInterface(),
        SLibraryInterface(),
        SObjectInterface(),
      };

  /// This is used to sort the interfaces by priority.
  ///
  /// Priority is used to determine which interface to use when pushing a object to the stack,
  /// for specificly classes that inherit from another class.
  ///
  /// Subclasses should have a higher priority than their parent class.
  /// This is a fix to a problem where the parent class would be used instead of the subclass.
  static Set<SInterface>? _sortedInterfaces;

  static Set<SInterface> get interfaces {
    _sortedInterfaces ??=
        (_interfaces.toList()..sort((a, b) => b.priority - a.priority)).toSet();
    return _sortedInterfaces!;
  }

  static Map<String, List<Enum>> get enums => {
        "SKitType": SKitType.values,
      };

  /// Initializes the lua state.
  /// This includes opening all libraries and adding all enums and statics to the global table.
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
        await addGlobal(interface_.className, interface_.staticTable);
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
    final stack = _formatStack();
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
    } else if (value is LEntry) {
      state.pushDartFunction((state) async {
        try {
          List<dynamic> args = [];
          Map<dynamic, dynamic> namedArgs = {};
          if (value.hasNamedArgs &&
              state.getTop() > value.numOfPositionalArgs &&
              state.isTable(state.getTop())) {
            Arceus.talker.debug("Named args");
            namedArgs = getFromTop();
          }
          for (final arg in value.args.entries
              .where(
                (element) => element.value.positional,
              )
              .toList()
              .reversed) {
            final argValue = getFromTop(pop: false);
            // Attempt to cast the argument to the expected type.
            // It will return null if the cast fails.
            final trueValue = arg.value.cast(argValue);
            if (trueValue == null) {
              if (!arg.value.required) {
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
          // Arceus.talker.debug("Args: $finalArgs");
          // Arceus.talker.debug("Before:\n$stack");
          // Arceus.talker.debug("After:\n${_formatStack()}");
          if (value.returnType == null) {
            // Means that the function doesn't return anything, so just call it.
            await Function.apply(value.func, finalArgs,
                namedArgs.map((key, value) {
              return MapEntry(Symbol(key), value);
            }));
          } else {
            // Means that the function returns something, so call it and push the result to the stack.
            final result =
                await Function.apply(value.func, finalArgs, namedArgs.map(
              (key, value) {
                return MapEntry(Symbol(key), value);
              },
            ));
            await _pushToStack(result);
          }
          return 1;
        } catch (e, st) {
          Arceus.talker.error("", e, st);
          rethrow;
        }
      });
    } else if (value is LField) {
      _pushToStack(value.value);
    } else {
      Arceus.talker.error("Could not push to stack: $value");
      Arceus.talker.debug("Before:\n$stack");
      Arceus.talker.debug("After:\n${_formatStack()}");
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
    /// The regex for hex numbers.
    /// Lua Dardo should be able to handle this, however, it doesn't.
    /// So we need to replace it with the actual number as a workaround.
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
    stopwatch.stop();
    if (!successful) {
      /// If it wasn't successful, print the error and return null
      state.error();
      return null;
    }

    /// If it was successful, return the result.
    final result = getFromTop();
    Arceus.talker
        .info("Lua result in ${stopwatch.elapsedMilliseconds}ms: $result");
    return result;
  }

  // Gets the interface for an object.
  static SInterface? getInterface(Object object) {
    for (final interface_ in interfaces) {
      if (interface_.isType(object)) {
        // Arceus.talker.debug(
        //     "Found interface: ${interface_.className} for object: $object");
        return interface_;
      }
    }
    return null;
  }

  static SInterface? getInterfaceFromType(Type type) {
    for (final interface_ in interfaces) {
      if (interface_.equalsType(type)) {
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

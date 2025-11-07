import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:reyveld/extensions.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/scripting/sinterface.dart';
import 'package:reyveld/security/authveld.dart' show AuthVeldException;
import 'package:reyveld/security/certificate/certificate.dart';
import 'package:reyveld/skit/skit.dart' show SKitType;
import 'package:reyveld/uuid.dart';
import 'package:lua_dardo_async/lua.dart';
import 'interfaces.dart' as portal;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef LuaArgs = ({List positional, Map named});
typedef LuaResult = ({
  dynamic result,
  Stopwatch processTime,
  String? processId
});

/// The main class for running lua scripts.
class Lua {
  final WebSocketChannel? socket;

  final Set<Stopwatch> _stopwatches = {};

  final Map<LuaState, String?> _processIds = {};

  SCertificate? certificate;

  Lua({this.socket, this.certificate});

  /// A map of all objects in the lua state.
  ///
  /// When pushing a object to the stack, an unique hash is generated and
  /// a duplicate of the SInterface with the object as its value is added to this map.
  final Map<LuaState, Map<String, SInterface>> _objects = {};

  static final Map<String, String> classHashes = {};

  /// A set of all interfaces in the lua state.

  static String getClassHash(String className) =>
      classHashes[className] ??= generateUUID();

  /// A set of all interfaces in the lua state, sorted by priority.
  ///
  /// Priority is used to determine which interface to use when pushing a object to the stack,
  /// for specificly classes that inherit from another class.
  ///
  /// Subclasses should have a higher priority than their parent class.
  /// This is a fix to a problem where the parent class would be used instead of the subclass.
  ///
  /// NOTE: Do not try to cache this set, as it will only use a single instance of the interface when pushing object,
  /// and not a new instance every time; Which will break logic in Lua.
  static Set<SInterface> get interfaces =>
      (portal.interfaces.toList()..sort((a, b) => b.priority - a.priority))
          .toSet();

  static Map<String, List<Enum>> get enums => {
        "SKitType": SKitType.values,
      };

  /// Code effects are functions that are applied to the lua code before it is compiled.
  /// This is used to clean up the lua code before it is compiled, like
  /// replacing hex numbers with their decimal counterparts and removing type definitions.
  static List<String Function(String)> get codeEffects => [
        (code) {
          /// Lua Dardo should be able to handle hex numbers, however, it doesn't.
          /// So we need to replace it with the actual number as a workaround.
          final hexExp = RegExp(r"0x([0-9A-f]+)");
          while (hexExp.hasMatch(code)) {
            final match = hexExp.firstMatch(code)!;
            code = code.replaceRange(match.start, match.end,
                int.parse(match.group(1)!, radix: 16).toString());
          }
          return code;
        },
        (code) {
          /// Remove type definitions.
          /// Lua Dardo doesn't support type definitions, so we need to remove them before compiling.
          final typeDefRegExp =
              RegExp(r"(?:local)?\s*(\w[\w\d]*)\s*:\s*\w[\w\d]*");
          while (typeDefRegExp.hasMatch(code)) {
            final match = typeDefRegExp.firstMatch(code)!;
            code = code.replaceRange(match.start, match.end, match.group(1)!);
          }
          return code;
        },
      ];

  /// Initializes the lua state.
  /// This includes opening all libraries and adding all enums and statics to the global table.
  Future<void> _init(LuaState state) async {
    /// Add all enums.
    for (final enum_ in enums.entries) {
      final table = <String, dynamic>{};
      for (final value in enum_.value) {
        table[value.name] = value.index;
      }
      await addGlobal(state, enum_.key, table);
    }

    // Add all static exports as global object.
    for (final interface_ in interfaces) {
      await addGlobal(state, interface_.className, interface_.staticTable);
    }

    await addGlobal(state, "is", (Lua lua, LuaState state) async {
      final obj = await lua.getFromTop<Object>(state);
      final interface = await lua.getFromTop<SInterface>(state);
      return interface?.isType(obj) ?? false;
    });
  }

  /// Adds a global to the Lua state.
  ///
  /// [name] is the name of the global.
  ///
  /// [value] is the table to add as the global.
  ///
  /// This will push the table to the stack and then set the global with the given name.
  Future<void> addGlobal(LuaState state, String name, dynamic value) async {
    // if (table == null) {
    //   return;
    // }
    await _pushToStack(state, value);
    await state.setGlobal(name);
  }

  SInterface? _getObject(LuaState state, String hash) => _objects[state]?[hash];
  void _setObject(LuaState state, String hash, SInterface interface_) =>
      _objects[state]![hash] = interface_;

  /// Pushes a value to the stack.
  Future<void> _pushToStack(LuaState state, dynamic value) async {
    if (value is String) {
      state.pushString(value);
    } else if (value is int) {
      state.pushInteger(value);
    } else if (value is bool) {
      state.pushBoolean(value);
    } else if (value is double) {
      state.pushNumber(value);
    } else if (value is Map) {
      state.newTable();
      for (final key in value.keys) {
        await _pushToStack(state, key);
        await _pushToStack(state, value[key]);
        await state.setTable(state.getTop() - 2);
      }
    } else if (value is Object && getInterface(value) != null) {
      final interface_ = getInterface(value)!..object = value;
      Reyveld.talker.verbose("Wrapping $value in $interface_.");
      final hash = generateUUID();
      _setObject(state, hash, interface_);
      final table = interface_.toLua(hash);
      await _pushToStack(state, table);
    } else if (value is FutureOr<dynamic> Function(Lua, LuaState)) {
      state.pushDartFunction((state) async {
        await _pushToStack(state, await value(this, state));
        return 1;
      });
    } else if (value is LEntry) {
      state.pushDartFunction((state) async {
        List<dynamic> args = [];

        while (state.getTop() > 0) {
          args.add(await getFromTop(state));
          if (args.length >=
              value.positionalArgCount + (value.hasNamedArgs ? 1 : 0)) {
            break;
          }
        }

        /// Reverse the args so that they are in the correct order.
        final finalArgs = args.reversed.toList()..removeWhere((e) => e == null);

        Map namedArgs = {};

        if (value.hasNamedArgs &&
            finalArgs.length >= value.positionalArgCount) {
          if (finalArgs.lastOrNull is Map) {
            namedArgs = finalArgs.removeLast();
          }
        }

        /// Checking positional arguments
        for (int i = 0; i < finalArgs.length; i++) {
          final argValue = finalArgs[i];
          final argType = value.args.elementAt(i);
          if (argType.cast(argValue) == null && argType.required) {
            throw Exception(
                "Type Mismatch for argument $argType at position $i! Expected ${argType.type} but got ${argValue.runtimeType}");
          } else {
            finalArgs[i] = argType.cast(argValue);
          }
        }

        /// Checking named arguments
        for (final key in namedArgs.keys) {
          final argValue = namedArgs[key];
          final argType = value.namedArgs.where((e) => e.name == key).single;
          if (argType.cast(argValue) == null && argType.required) {
            throw Exception(
                "Type Mismatch for argument $argType at position $key! Expected ${argType.type} but got ${argValue.runtimeType}");
          } else {
            namedArgs[key] = argType.cast(argValue);
          }
        }

        /// If the function has a security check, check it with the arguments.
        Reyveld.talker.verbose(
            "Checking security for function '${value.name}' with $finalArgs$namedArgs.");
        if (value.securityCheck != null) {
          if (certificate == null) {
            throw AuthVeldException(
                "Certificate not found, so assuming no access.");
          } else if (!certificate!.authorized) {
            throw AuthVeldException(
                "Certificate (Token: '${certificate!.id}') not authorized!");
          }
          if (!(certificate?.completeAccess ?? false)) {
            if (value.securityCheckPassed == null) {
              final result = await Lua().run(value.securityCheck!, args: {
                "cert": certificate,
                "args": finalArgs,
                "named": namedArgs,
                "object": value.interface_?.object
              });
              if (result.result is bool) {
                value.securityCheckPassed = result.result;
              } else if (result.result is String) {
                throw AuthVeldException(result.result);
              } else {
                value.securityCheckPassed = false;
              }
            }
            if (value.securityCheckPassed == false) {
              throw AuthVeldException("Access denied.");
            }
          }
        }
        Reyveld.talker.verbose(
            "Calling function '${value.name}' with $finalArgs$namedArgs.");
        try {
          if (value.returnType == null) {
            // Means that the function doesn't return anything, so just call it.
            await Function.apply(
                value.func,
                [
                  value.passLua ? this : null,
                  value.passState ? state : null,
                  ...finalArgs
                ]..removeWhere((e) => e == null), namedArgs.map((key, value) {
              return MapEntry(Symbol(key), value);
            }));
            return 0;
          } else {
            // Means that the function returns something, so call it and push the result to the stack.
            final result = await Function.apply(
                value.func,
                [
                  value.passLua ? this : null,
                  value.passState ? state : null,
                  ...finalArgs
                ]..removeWhere((e) => e == null), namedArgs.map(
              (key, value) {
                return MapEntry(Symbol(key), value);
              },
            ));
            Reyveld.talker.verbose(
                "Result for call to '${value.name}'$finalArgs$namedArgs: $result");
            await _pushToStack(state, result);
            return 1;
          }
        } catch (e, st) {
          Reyveld.talker.error(
              "Error when calling '${value.name}' with $finalArgs$namedArgs.",
              e,
              st);
          return 0;
        }
      });
    } else if (value is LField) {
      await _pushToStack(state, value.value);
    } else if (value == null) {
      state.pushNil();
    } else {
      Reyveld.talker.error("Could not push to stack: $value");
    }
  }

  /// Gets a value from the top of the stack.
  Future<T?> getFromTop<T>(LuaState state, {bool pop = true}) async {
    dynamic result;
    try {
      if (state.isString(state.getTop())) {
        result = state.toStr(state.getTop());
        if (T != String) {
          try {
            result = num.parse(result);
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
      } else if (state.isFunction(state.getTop())) {
        result = LuaFuncRef(this, state, await state.ref(luaRegistryIndex));
        await state.rawGetI(luaRegistryIndex, (result as LuaFuncRef).ref);
      } else if (state.isTable(state.getTop())) {
        /// If the top of the stack is a table, get the table and check if it has an objHash key.
        final table = await _getTableFromState(state);
        if (table.containsKey("objHash") &&
            _getObject(state, table["objHash"]) != null) {
          /// If the table has an objHash key, then it means it is an interface for an object,
          /// so get the object and return it.
          result = _getObject(state, table["objHash"])!.object;
        } else if (table.containsKey("__hash__") &&
            interfaces.any((key) => key.classHash == table["__hash__"])) {
          result = interfaces
              .firstWhere((key) => key.classHash == table["__hash__"]);
        } else if (table.keys.every((key) => key is int)) {
          result = table.values.toList();
        } else {
          result = table;
        }
      } else if (state.isNoneOrNil(state.getTop())) {
        result = null;
      } else {
        result = null;
      }
    } catch (e, st) {
      Reyveld.talker.error(e, st);
    }

    if (pop) {
      if (state.getTop() != 0) {
        state.pop(1);
      }
    }
    return result;
  }

  /// Returns a table from the lua state.
  Future<Map> _getTableFromState(LuaState state) async {
    Map resultTable = {};
    state.pushNil();
    while (state.next(state.getTop() - 1)) {
      dynamic value = await getFromTop(state);
      dynamic key = await getFromTop(state);
      if (key is String && resultTable.isEmpty) {
        resultTable = <String, dynamic>{};
      } else if (key is int && resultTable.isEmpty) {
        resultTable = <int, dynamic>{};
      }
      resultTable[key] = value;
      await _pushToStack(state, key);
    }
    return resultTable;
  }

  String? getPID(LuaState state) => _processIds[state];
  void setPID(LuaState state, String? pid) => _processIds[state] = pid;

  /// Compiles a lua project.
  Future<String> _compile(String entrypoint) async {
    final stringPlaceholder = "⭐🌃✨🌟";
    String compiled = entrypoint;
    final strings = [];
    final strExp = RegExp("\"([^\"]*)\"|'([^']*)'");
    while (strExp.hasMatch(compiled)) {
      final match = strExp.firstMatch(compiled)!;

      /// Replace the string with a placeholder to add string back later.
      /// This is done so that anything inside the string is not effected by code effects.
      compiled = compiled.replaceFirst(match[0]!, stringPlaceholder);
      strings.add(match[1] ?? match[2]!);
    }
    for (final effect in codeEffects) {
      compiled = effect(compiled);
    }
    while (compiled.contains(stringPlaceholder)) {
      compiled = compiled.replaceFirst(
          stringPlaceholder, "\"${_formatPaths(strings.removeAt(0))}\"");
    }

    return compiled;
  }

  /// This is done so that windows paths backslashes are converted to forward slashes.
  String _formatPaths(String path) {
    if (Uri.tryParse(path) != null) {
      return path.removeWindowsSlashes();
    }
    return path;
  }

  Future<void> awaitForCompletion() async {
    while (_stopwatches.any((stopwatch) => stopwatch.isRunning)) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  final Queue<LuaState> _removeQueue = Queue<LuaState>();

  Future<List<dynamic>> stack(LuaState state) async {
    final stack = [];
    while (state.getTop() > 0) {
      stack.add(await getFromTop(state));
    }
    for (final x in stack) {
      await _pushToStack(state, x);
    }
    return stack;
  }

  /// Runs a lua script.
  Future<LuaResult> run(String entrypoint, {Map<String, dynamic>? args}) async {
    /// Resets the stopwatch and starts it, to track process time,
    /// and to notify if its done.

    while (_removeQueue.isNotEmpty) {
      final state = _removeQueue.removeFirst();
      _objects.remove(state);
    }
    final stopwatch = Stopwatch();
    _stopwatches.add(stopwatch);
    stopwatch.start();
    final code = await _compile(entrypoint).then((value) => value.trim());

    final state = LuaState.newState();

    _processIds[state] = null;
    _objects[state] = {};

    await _init(state);

    if (args != null) {
      Reyveld.talker.info("Arguments: $args");
      for (final arg in args.entries) {
        await addGlobal(state, arg.key, arg.value);
      }
    }

    final thread = state.loadString(code);

    if (thread != ThreadStatus.luaOk) {
      state.error();
      return (
        result: null,
        processTime: stopwatch,
        processId: _processIds[state]
      );
    }

    // Run the lua code and see if it was successful
    final successful = await state.pCall(0, 1, 0) == ThreadStatus.luaOk;
    stopwatch.stop();
    _removeQueue.add(state);
    if (!successful) {
      /// If it wasn't successful, print the error and return null
      Reyveld.talker.error("Objects: ${_objects[state]}");
      state.error();
      return (
        result: null,
        processTime: stopwatch,
        processId: _processIds[state]
      );
    }

    /// If it was successful, return the result.
    final result = await getFromTop(state);
    return (
      result: result,
      processTime: stopwatch,
      processId: _processIds[state]
    );
  }

  /// Gets the interface for an object.
  static SInterface? getInterface(Object object) {
    for (final interface_ in interfaces) {
      if (interface_.isType(object)) {
        return interface_;
      }
    }
    return null;
  }

  /// Gets the interface for a type.
  /// Used for generating docs.
  static SInterface? getInterfaceFromType(Type type) {
    for (final interface_ in interfaces) {
      if (interface_.equalsType(type)) {
        return interface_;
      }
    }
    return null;
  }

  /// Generates a docs file for all of the interfaces.
  static Stream<String> generateDocs() async* {
    final dir =
        Directory("${Reyveld.appDataPath}/docs/${Reyveld.version.toString()}");
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
      for (final interface_ in interfaces) {
        yield interface_.className;
        await interface_.generateDocs();
      }
      yield "Enums";
      await _generateEnumDocs();
      yield "Others";
      await _generateOtherDocs();
    } catch (e) {
      Reyveld.talker.error(e.toString());
    }
  }

  // Generates a docs file for all of the enums.
  static Future<void> _generateEnumDocs() async {
    final doc = File(
        "${Reyveld.appDataPath}/docs/${Reyveld.version.toString()}/enums.lua");
    await doc.create(recursive: true);
    await doc.writeAsString("""
---@meta _

${_formatEnums()}
""");
  }

  static Future<void> _generateOtherDocs() async {
    final doc = File(
        "${Reyveld.appDataPath}/docs/${Reyveld.version.toString()}/others.lua");
    await doc.create(recursive: true);
    await doc.writeAsString("""
---@meta _

---Checks if an object is an instance of a class.
---@param obj table
---@param class table
---@return boolean
function is(obj, class) end
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

/// A reference to a lua function.
///
/// This is used to call lua functions from dart.
/// What it does is register the function in the lua registry, and then when [call] is called,
/// it will push the function back to the stack, and then call it.
///
/// To unregister the function from the registry when it is no longer needed, use [unregister].
/// Should always be done, as it will prevent memory leaks or overflows.
final class LuaFuncRef {
  final Lua lua;
  final LuaState state;
  final int ref;

  const LuaFuncRef(this.lua, this.state, this.ref);

  Future<T?> call<T>(List<dynamic> args) async {
    await state.rawGetI(luaRegistryIndex, ref);
    for (final arg in args) {
      await lua._pushToStack(state, arg);
    }
    if (state.isNil(state.getTop())) {
      return null;
    }
    await state.call(args.length, 1);
    return await lua.getFromTop(state);
  }

  /// Unregisters the function from the registry.
  ///
  /// This should always be called when the reference is no longer needed.
  Future<void> unregister() async => await state.unRef(luaRegistryIndex, ref);
}

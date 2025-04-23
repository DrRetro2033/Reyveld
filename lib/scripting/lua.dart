import 'dart:async';

import 'package:arceus/arceus.dart';
import 'package:arceus/scripting/list.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/version_control/star.dart';
import 'package:lua_dardo_async/debug.dart';
import 'package:lua_dardo_async/lua.dart';

import '../skit/skit.dart';

class Lua {
  final LuaState state;

  Lua() : state = LuaState.newState();

  final Set<LuaScript> _scripts = {};

  final Map<String, SInterface> _objects = {};

  static Set<SInterface> get interfaces => {
        SKitInterface(),
        ConstellationInterface(),
        StarInterface(),
        SArchiveInterface(),
        SFileInterface(),
        SRFileInterface(),
      };

  Future<void> init() async {
    await _init(state);
  }

  Future<void> _init(LuaState state) async {
    await state.openLibs();
    await addGlobal("SKitType", {
      "unspecified": SKitType.unspecified.index,
      "constellation": SKitType.constellation.index,
    });

    await addGlobal("addScript", (Lua state) async {
      await addScript(await state.getFromTop<String>(),
          name: await state.getFromTop<String>());
    });

    for (final interface_ in interfaces) {
      if (interface_.statics.isNotEmpty) {
        await addGlobal(interface_.className, interface_.statics);
      }
    }
  }

  void printStack([String message = "Default message"]) {
    print(message);
    state.printStack();
    print("");
  }

  Future<void> addGlobal(String name, dynamic table) async {
    await _pushToStack(table);
    await state.setGlobal(name);
  }

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
    } else if (value is List<dynamic>) {
      final interface_ = ListInterface()..object = value;
      final hash = _createUniqueObjectHash();
      _objects[hash] = interface_;
      await _pushToStack(interface_.toLua(this, hash));
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
        await _pushToStack(await value.$4(this));
        return 1;
      });
    } else {
      Arceus.talker.error("Could not push to stack: $value");
    }
  }

  Future<T> getFromTop<T>({bool pop = true, bool optional = false}) async {
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
        final table = await _getTableFromState();

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

    if (optional && result is! T) {
      return Future.value(null as T?);
    }

    if (pop) {
      if (state.getTop() != 0) {
        state.pop(1);
      }
    }
    return result as T;
  }

  String _createUniqueObjectHash() => generateUniqueHash(_objects.keys.toSet());

  Future<Map<String, dynamic>> _getTableFromState() async {
    Map<String, dynamic> resultTable = {};
    state.pushNil();
    while (state.next(state.getTop() - 1)) {
      dynamic value = await getFromTop();
      String key = await getFromTop<String>();
      resultTable[key] = value;
      _pushToStack(key);
    }
    return resultTable;
  }

  Future<void> addScript(String script, {String name = "run.lua"}) async {
    Arceus.talker.debug("Attempting to add script: $name \n$script");
    final testState = LuaState.newState();
    await _init(testState);
    final successful = await testState.doString(_compile(script));
    if (!successful) {
      try {
        state.error();
      } catch (e) {
        Arceus.talker.critical("Could not add script: $e");
      }
      return;
    }
    if (!_scripts.any((e) => e.name == name)) {
      _scripts.removeWhere((e) => e.name == name);
    }
    _scripts.add(LuaScript(name, script));
  }

  String _compile([String? extra]) {
    return [..._scripts.map((e) => e.code), extra].join("\n");
  }

  Future<dynamic> run([String? extra]) async {
    final successful = await state.doString(_compile(extra).trim());
    if (!successful) {
      state.error();
    }
    final result = await getFromTop(optional: true);
    Arceus.talker.debug("Lua result: $result");
    return result;
  }

  static SInterface? getInterface(Object object) {
    for (final interface_ in interfaces) {
      if (interface_.isType(object)) {
        return interface_;
      }
    }
    return null;
  }

  static Future<void> generateDocs() async {
    for (final interface_ in interfaces) {
      await interface_.generateDocs();
    }
  }
}

class LuaScript {
  final String name;
  final String code;

  LuaScript(this.name, this.code);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is LuaScript && other.name == name;
}

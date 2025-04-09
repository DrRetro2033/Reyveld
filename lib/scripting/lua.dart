import 'dart:async';

import 'package:arceus/arceus.dart';
import 'package:arceus/scripting/object.dart';
import 'package:lua_dardo_async/debug.dart';
import 'package:lua_dardo_async/lua.dart';

import '../skit/skit.dart';

class Lua {
  final LuaState state;

  Lua([LuaState? state]) : state = state ?? LuaState.newState();

  final Set<LuaScript> _scripts = {};

  Future<void> init() async {
    await state.openLibs();
    await addGlobal("SKit", {
      "open": (Lua state) async {
        final path = await state.getFromStack<String>(idx: 1);
        return await SKit.open(path);
      }
    });
  }

  void printStack() => state.printStack();

  Future<void> addGlobal(String name, dynamic table) async {
    await _pushToStack(table);
    await state.setGlobal(name);
  }

  Future<void> _pushToStack(dynamic value) async {
    if (value is String) {
      state.pushString(value);
    }
    if (value is int) {
      state.pushInteger(value);
    }
    if (value is bool) {
      state.pushBoolean(value);
    }
    if (value is double) {
      state.pushNumber(value);
    }
    if (value is Map<String, dynamic>) {
      state.newTable();
      for (String key in value.keys) {
        await _pushToStack(key);
        await _pushToStack(value[key]);
        await state.setTable(-3);
      }
    }
    if (value is List<dynamic>) {
      state.newTable();
      for (int i = 0; i < value.length; i++) {
        await _pushToStack(i);
        await _pushToStack(value[i]);
        await state.setTable(-3);
      }
    }
    if (value is LuaObject) {
      await _pushToStack(value.toLua());
    }
    if (value is FutureOr<dynamic> Function(Lua)) {
      state.pushDartFunction((state) async {
        await _pushToStack(await value(this));
        return 1;
      });
    }
  }

  Future<bool> isFromStack<T>({int idx = -1}) async {
    final item = await getFromStack(idx: idx, pop: false);
    return item is T;
  }

  Future<T> getFromStack<T>({int idx = -1, bool pop = true}) async {
    dynamic result;
    if (state.isString(idx)) {
      try {
        int x = int.parse(state.toStr(idx) ?? "");
        result = x;
      } catch (e) {
        result = state.toStr(idx);
      }
    }
    if (state.isInteger(idx)) {
      result = state.toInteger(idx);
    }
    if (state.isNumber(idx)) {
      result = state.toNumber(idx);
    }
    if (state.isBoolean(idx)) {
      result = state.toBoolean(idx);
    }
    if (state.isTable(idx)) {
      final table = await _getTableFromState();
      if (LuaObject.fromLua(table) != null) {
        result = LuaObject.fromLua(table);
      }
      result = table;
    }
    if (state.isNil(idx)) {
      result = null;
    }
    // printStack();
    if (pop) {
      try {
        state.pop(1);
      } catch (e) {
        Arceus.talker.error("Error popping from stack: $e");
      }
    }
    return result as T;
  }

  Future<Map<String, dynamic>> _getTableFromState() async {
    Map<String, dynamic> resultTable = {};
    if (state.isTable(-1)) {
      state.pushNil();
      while (state.next(-2)) {
        String? key = state.toStr(-2);
        dynamic value = await getFromStack();
        try {
          if (value is String) {
            int x = int.parse(value);
            value = x;
          }
        } catch (e) {
          // Do nothing
        }
        resultTable[key!] = value;
      }
    }
    return resultTable;
  }

  void addScript(String script, {String name = "run.lua"}) =>
      _scripts.add(LuaScript(name, script));

  String _compile() {
    return _scripts.map((e) => e.code).join("\n");
  }

  Future<dynamic> run() async {
    await state.doString(_compile());
    return await getFromStack();
  }
}

class LuaScript {
  final String name;
  final String code;

  LuaScript(this.name, this.code);
}

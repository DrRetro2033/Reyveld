import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobjects/sobjects.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/version_control/star.dart';
import 'package:lua_dardo_async/debug.dart';
import 'package:lua_dardo_async/lua.dart';

import '../skit/skit.dart';

class Lua {
  final LuaState state;

  Lua([LuaState? state]) : state = state ?? LuaState.newState();

  final Set<LuaScript> _scripts = {};

  final Map<String, SInterface> _objects = {};

  static Set<SInterface> get interfaces => {
        SKitInterface(),
        SHeaderInterface(),
        ConstellationInterface(),
        StarInterface(),
        SArchiveInterface(),
      };

  Future<void> init() async {
    await state.openLibs();
    await addGlobal("SKitType", {
      "unspecified": SKitType.unspecified.index,
      "constellation": SKitType.constellation.index,
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
      state.newTable();
      for (int i = 0; i < value.length; i++) {
        await _pushToStack(i.toString());
        await _pushToStack(value[i]);
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
    } else {
      Arceus.talker.error("Could not push to stack: $value");
    }
  }

  Future<T> getFromTop<T>({bool pop = true}) async {
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

  void addScript(String script, {String name = "run.lua"}) =>
      _scripts.add(LuaScript(name, script));

  String _compile() {
    return _scripts.map((e) => e.code).join("\n");
  }

  Future<dynamic> run() async {
    await state.doString(_compile());
    final result = await getFromTop();
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

  static Future<void> logInterface() async {
    final log = File(
        "${Arceus.appDataPath}/interfaces/interface-${Arceus.currentVersion.toString()}.md");
    await log.create(recursive: true);
    log.writeAsString("");
    for (final interface_ in interfaces) {
      await log.writeAsString('${interface_.interface_.trim()}\n',
          mode: FileMode.append);
      await log.writeAsString('\n', mode: FileMode.append);
    }
  }
}

class LuaScript {
  final String name;
  final String code;

  LuaScript(this.name, this.code);
}

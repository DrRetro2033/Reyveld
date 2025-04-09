import 'package:arceus/scripting/lua.dart';
import 'package:arceus/uuid.dart';

mixin LuaObject {
  String get luaClassName;

  static final Map<String, LuaObject> _objects = {};
  Map<String, dynamic> toMap();

  String? _luaHash;
  String get luaHash => _luaHash ??= createUniqueHash();

  String createUniqueHash() => generateUniqueHash(_objects.keys.toSet());

  Map<String, dynamic> toLua() {
    _objects[luaHash] = this;
    return {
      "class": luaClassName,
      "hash": luaHash,
      "toString": (Lua state) {
        return toString();
      },
      ...toMap(),
    };
  }

  static LuaObject? fromLua(Map<String, dynamic> map) =>
      map.containsKey("hash") ? _objects[map["hash"]] : null;

  @override
  String toString() => toLua().toString();
}

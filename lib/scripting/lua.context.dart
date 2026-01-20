part of 'lua.dart';

class LuaContext {
  String pid;
  final String script;
  final Stopwatch stopwatch = Stopwatch();
  final Map<String, SInterface> objects = {};
  LuaContext({String? pid, required this.script}) : pid = pid ?? generateUUID();

  void start() => stopwatch.start();
}

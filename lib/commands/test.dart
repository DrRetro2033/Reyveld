import 'dart:async';
import 'dart:typed_data';

import 'package:arceus/scripting/squirrel.dart';
import 'package:args/command_runner.dart';

class TestCommand extends Command {
  @override
  String get name => "test";

  @override
  String get description => "Run tests.";

  @override
  bool get hidden => true;

  TestCommand() {
    addSubcommand(TestSquirrelCommand());
    addSubcommand(TestCrashHandlerCommand());
  }
}

class TestSquirrelCommand extends Command {
  @override
  String get name => "squirrel";

  @override
  String get description => "Run tests.";

  @override
  bool get hidden => true;

  @override
  Future<void> run() async {
    final runner = SquirrelVM();
    runner.addAPITable(funcs: [
      SAPIFunc('test', {'a': sqInteger, 'b': sqInteger}, (params, context) {
        return params['a'] + params['b'];
      })
    ]);
    final bytes = ByteData(128);
    runner.addAPITable(name: "file", funcs: [
      SAPIFunc("ru8", {"address": sqInteger}, (params, context) {
        return bytes.getUint8(params["address"]);
      }, context: bytes)
    ], vars: {
      "name": "pokemon.pk9"
    });
    runner.addScript("""
function main() {
  local testValue = arceus.test(1, 2);
  local test2 = file.ru8(0);
  return file.name;
}
""", name: "main.nut");
    runner.addScript("""
function testImport(t) {
  return t + 4;
} 
""", name: "test.nut");

    final result = runner.call("main");
    print(result);
    runner.dispose();
    return;
  }
}

class TestCrashHandlerCommand extends Command {
  @override
  String get name => "crash";

  @override
  String get description => "Crashes the program to test the crash handler.";

  @override
  Future<void> run() async {
    throw Exception("Test Crash.");
  }
}

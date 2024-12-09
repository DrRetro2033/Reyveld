import 'dart:ffi';

import 'package:test/test.dart';

import 'package:arceus/scripting/squirrel.dart';
import 'package:arceus/scripting/squirrel_bindings_generated.dart';

void main() {
  test("Squirrel Test", () {
    final vm = Squirrel.run("""
function foo(i,f,s)
{
  return i+f+s+egg();
}

function bar(a,t) {
  return a+t;
}
""");

    Squirrel.createAPI(vm, [
      SquirrelFunction(
          "egg", {}, (Pointer<SQVM> vm, Map<String, dynamic> params) => 42)
    ]);

    final result1 = Squirrel.call(vm, "foo", [1, 2, 3]);
    print(result1);
    final result2 = Squirrel.call(vm, "bar", [4, 5]);
    print(result2);
  });
}

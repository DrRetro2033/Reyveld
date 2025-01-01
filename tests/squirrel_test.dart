import 'package:test/test.dart';

import 'package:arceus/scripting/squirrel.dart';

void main() {
  test("Squirrel Test", () {
    final vm = Squirrel("""
function foo(i,f,s)
{
  return i+f+s+egg();
}

function bar(a,t) {
  return a+t;
}
""");

    vm.createAPI(
        [SquirrelFunction("egg", {}, (Map<String, dynamic> params) => 42)]);

    final result1 = vm.call("foo", args: [1, 2, 3]);
    print(result1);
    final result2 = vm.call("bar", args: [4, 5]);
    print(result2);
  });
}

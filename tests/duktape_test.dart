import 'dart:ffi';

import 'package:test/test.dart';

import '../bin/scripting/duktape_bindings_generated.dart';
import '../bin/scripting/duktape.dart';

void main() {
  test("Duktape Test", () {
    Duktape.init("C:/Repos/arceus");
    final duktape = Duktape(apiFunctions: [
      DuktapeFunction("getExample", {},
          (Pointer<duk_hthread> ctx, Map<String, dynamic> params) {
        return 2;
      }),
    ]);
    print(duktape.eval("0x2A+getExample()"));

    duktape.dispose();
  });
}

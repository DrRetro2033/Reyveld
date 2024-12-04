import 'dart:ffi';
import 'dart:typed_data';

import '../addon.dart';
import '../duktape.dart';
import '../duktape_bindings_generated.dart';
import '../../version_control/dossier.dart';

class PatternAdddonContext extends AddonContext {
  PatternAdddonContext(super.addon) : super();

  Plasma? plasma;

  @override
  List<DuktapeFunction> get functions => [
        DuktapeFunction('ru8', {'address': DuktapeType.int}, readU8),
        DuktapeFunction('ru16',
            {'address': DuktapeType.int, 'endian': DuktapeType.bool}, readU16),
        DuktapeFunction('ru32',
            {'address': DuktapeType.int, 'endian': DuktapeType.bool}, readU32),
        DuktapeFunction('ru64',
            {'address': DuktapeType.int, 'endian': DuktapeType.bool}, readU64),
      ];

  Map<String, dynamic> read(Plasma plasma) {
    this.plasma = plasma;
    final ctx = Duktape.bindings
        .duk_create_heap(nullptr, nullptr, nullptr, nullptr, nullptr);
    createAPI(ctx, functions);
    eval(ctx, addon.code);
    final result = call(ctx, "read", ["test", "test"]);
    print(result);
    dispose(ctx);
    return result;
  }

  int readU8(Pointer<duk_hthread> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint8(params['address'] as int);
  }

  int readU16(Pointer<duk_hthread> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint16(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int readU32(Pointer<duk_hthread> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint32(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int readU64(Pointer<duk_hthread> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint64(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }
}

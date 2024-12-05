import 'dart:ffi';
import 'dart:typed_data';

import '../addon.dart';
import '../squirrel.dart';
import '../squirrel_bindings_generated.dart';
import '../../version_control/dossier.dart';

class PatternAdddonContext extends AddonContext {
  PatternAdddonContext(super.addon) : super();

  Plasma? plasma;

  @override
  List<SquirrelFunction> get functions => [
        SquirrelFunction(
            'ru8', {'address': tagSQObjectType.OT_INTEGER}, readU8),
        SquirrelFunction(
            'ru16',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': tagSQObjectType.OT_BOOL
            },
            readU16),
        SquirrelFunction(
            'ru32',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': tagSQObjectType.OT_BOOL
            },
            readU32),
        SquirrelFunction(
            'ru64',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': tagSQObjectType.OT_BOOL
            },
            readU64),
      ];

  Map<dynamic, dynamic> read(Plasma plasma) {
    this.plasma = plasma;
    final vm = Squirrel.run(addon.code);
    final result = Squirrel.call(vm, "read");
    Squirrel.dispose(vm);
    return result;
  }

  int readU8(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint8(params['address'] as int);
  }

  int readU16(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint16(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int readU32(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint32(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int readU64(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint64(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }
}

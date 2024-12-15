import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import '../addon.dart';
import '../squirrel.dart';
import '../squirrel_bindings_generated.dart';
import '../../version_control/dossier.dart';

class PatternAdddonContext extends AddonContext {
  PatternAdddonContext(super.addon);

  Plasma? plasma;

  @override
  List<String> get requiredFunctions => ["read", "write"];

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
        SquirrelFunction(
            'rchar8', {'address': tagSQObjectType.OT_INTEGER}, readChar8),
        SquirrelFunction(
            'rchar16',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': tagSQObjectType.OT_BOOL
            },
            readChar16),
      ];

  Map<dynamic, dynamic> read(Plasma plasma) {
    this.plasma = plasma;
    final vm = startVM();
    final result = Squirrel.call(vm, "read");
    Squirrel.dispose(vm);
    return result;
  }

  Map<dynamic, dynamic> summary(Plasma plasma) {
    this.plasma = plasma;
    final vm = startVM();
    final result = Squirrel.call(vm, "summary");
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

  String readChar8(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return utf8.decode([plasma!.data.getUint8(params['address'] as int)]);
  }

  String readChar16(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return String.fromCharCode(plasma!.data.getUint16(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big));
  }
}

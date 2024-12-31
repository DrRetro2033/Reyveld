import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:yaml/yaml.dart';

import '../addon.dart';
import '../squirrel.dart';
import '../squirrel_bindings_generated.dart';
import '../../version_control/dossier.dart';

class PatternAddonContext extends AddonContext {
  PatternAddonContext([super.addon]);

  Plasma? plasma;

  @override
  List<String> get requiredFunctions => ["read", "write"];

  @override
  List<SquirrelFunction> get functions => [
        SquirrelFunction(
            'ru8', {'address': tagSQObjectType.OT_INTEGER}, readU8),
        SquirrelFunction('r8', {'address': tagSQObjectType.OT_INTEGER}, read8),
        SquirrelFunction(
            'ru16',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true)
            },
            readU16),
        SquirrelFunction(
            'r16', {'address': tagSQObjectType.OT_INTEGER}, read16),
        SquirrelFunction(
            'ru32',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true)
            },
            readU32),
        SquirrelFunction(
            'r32', {'address': tagSQObjectType.OT_INTEGER}, read32),
        SquirrelFunction(
            'ru64',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true)
            },
            readU64),
        SquirrelFunction(
            'r64', {'address': tagSQObjectType.OT_INTEGER}, read64),
        SquirrelFunction(
            'rchar8', {'address': tagSQObjectType.OT_INTEGER}, readChar8),
        SquirrelFunction(
            'rchar16',
            {
              'address': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true)
            },
            readChar16),
        SquirrelFunction(
            'r8a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            read8Array),
        SquirrelFunction(
            'ru8a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            readU8Array),
        SquirrelFunction(
            'r16a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true),
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            read16Array),
        SquirrelFunction(
            'ru16a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true),
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            readU16Array),
        SquirrelFunction(
            'r32a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true),
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            read32Array),
        SquirrelFunction(
            'ru32a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true),
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            readU32Array),
        SquirrelFunction(
            'r64a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true),
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            read64Array),
        SquirrelFunction(
            'ru64a',
            {
              'start': tagSQObjectType.OT_INTEGER,
              'end': tagSQObjectType.OT_INTEGER,
              'endian': (tagSQObjectType.OT_BOOL, true),
              'invert': (tagSQObjectType.OT_BOOL, false)
            },
            readU64Array),
        SquirrelFunction(
          'rchar8a',
          {
            'start': tagSQObjectType.OT_INTEGER,
            'length': tagSQObjectType.OT_INTEGER,
            'other': {
              'endAtZero': true,
            }
          },
          readChar8Array,
        ),
        SquirrelFunction(
          'rchar16a',
          {
            'start': tagSQObjectType.OT_INTEGER,
            'length': tagSQObjectType.OT_INTEGER,
            'other': {'endian': true, 'endAtZero': true, 'invert': false}
          },
          readChar16Array,
        ),
        SquirrelFunction('reof', {}, getEOFAddress),
        SquirrelFunction(
            'chpass', {'name': tagSQObjectType.OT_STRING}, passCheck),
        SquirrelFunction(
            'chfail', {'name': tagSQObjectType.OT_STRING}, failCheck),
      ];

  bool doingMemoryTest = false;
  Map<String, bool> checks = {};

  Map<dynamic, dynamic> read(Plasma plasma, {bool doingMemoryTest = false}) {
    this.doingMemoryTest = doingMemoryTest;
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

  @override
  void test(YamlMap yaml) {
    if (yaml.containsKey('test-pattern-on') &&
        yaml['test-pattern-on'] != null) {
      final plasma = Plasma.fromFile(File(yaml['test-pattern-on'] as String));
      read(plasma, doingMemoryTest: true);
    }
  }

  int readU8(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint8(params['address'] as int);
  }

  int read8(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getInt8(params['address'] as int);
  }

  int readU16(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint16(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int read16(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getInt16(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int readU32(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint32(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int read32(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getInt32(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int readU64(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getUint64(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  int read64(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.getInt64(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big);
  }

  String readChar8(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return utf8.decode([plasma!.data.getUint8(params['address'] as int)]);
  }

  String readChar16(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return String.fromCharCode(plasma!.data.getUint16(params['address'] as int,
        (params['endian'] as bool) ? Endian.little : Endian.big));
  }

  List<int> readU8Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end) return [];
    List<int> data =
        plasma!.data.buffer.asUint8List(start, end - start).toList();
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> read8Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end) return [];
    List<int> data =
        plasma!.data.buffer.asInt8List(start, end - start).toList();
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> readU16Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end - 1) return [];
    List<int> data = [];
    for (int i = start; i < end; i += 2) {
      data.add(plasma!.data.getUint16(
          i, (params['endian'] as bool) ? Endian.little : Endian.big));
    }
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> read16Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end - 1) return [];
    List<int> data = [];
    for (int i = start; i < end; i += 2) {
      data.add(plasma!.data.getInt16(
          i, (params['endian'] as bool) ? Endian.little : Endian.big));
    }
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> readU32Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end - 3) return [];
    List<int> data = [];
    for (int i = start; i < end; i += 4) {
      data.add(plasma!.data.getUint32(
          i, (params['endian'] as bool) ? Endian.little : Endian.big));
    }
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> read32Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end - 3) return [];
    List<int> data = [];
    for (int i = start; i < end; i += 4) {
      data.add(plasma!.data.getInt32(
          i, (params['endian'] as bool) ? Endian.little : Endian.big));
    }
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> readU64Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end - 7) return [];
    List<int> data = [];
    for (int i = start; i < end; i += 8) {
      data.add(plasma!.data.getUint64(
          i, (params['endian'] as bool) ? Endian.little : Endian.big));
    }
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  List<int> read64Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    int end = params['end'] as int;
    if (end < 0) end = getEOFAddress(ctx, params);
    if (start >= end - 7) return [];
    List<int> data = [];
    for (int i = start; i < end; i += 8) {
      data.add(plasma!.data.getInt64(
          i, (params['endian'] as bool) ? Endian.little : Endian.big));
    }
    return params['invert'] as bool ? data.reversed.toList() : data;
  }

  String readChar8Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    final end = params['length'] as int;
    if (end <= 0) return '';
    List<int> data = [];
    for (int i = start; i < end; i += 1) {
      int char = plasma!.data.getUint8(i);
      if (params['other']['endAtZero'] as bool && char == 0) break;
      data.add(char);
    }
    return utf8.decode(data);
  }

  String readChar16Array(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final start = params['start'] as int;
    final length = params['length'] as int;
    if (length <= 0) return '';
    final end = start + length * 2;
    List<int> data = [];
    for (int i = start; i < end; i += 2) {
      int char = plasma!.data.getUint16(
          i, (params['other']['endian'] as bool) ? Endian.little : Endian.big);
      if (params['other']['endAtZero'] as bool && char == 0) break;
      data.add(char);
    }
    return String.fromCharCodes(
        params['other']['invert'] as bool ? data.reversed.toList() : data);
  }

  int getEOFAddress(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    return plasma!.data.lengthInBytes;
  }

  void passCheck(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final name = params['name'] as String;
    if (!doingMemoryTest) print("✅ $name");
    checks[name] = true;
  }

  void failCheck(Pointer<SQVM> ctx, Map<String, dynamic> params) {
    final name = params['name'] as String;
    if (!doingMemoryTest) print("❌ $name");
    checks[name] = false;
  }
}

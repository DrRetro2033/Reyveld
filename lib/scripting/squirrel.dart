import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/scripting/bindings.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

DynamicLibrary _getDylib() {
  if (Arceus.isDev) {
    return DynamicLibrary.open(
        "${const String.fromEnvironment('LIBRARY_PATH', defaultValue: 'C://Repos/arceus/')}/squirrel.dll");
  }
  if (Platform.isMacOS) {
    throw Exception("MacOS is not supported yet.");
  } else if (Platform.isLinux) {
    return DynamicLibrary.open("${Arceus.getLibraryPath()}/lib/squirrel.so");
  } else if (Platform.isWindows) {
    return DynamicLibrary.open("${Arceus.getLibraryPath()}/squirrel.dll");
  }
  throw Exception("Unsupported platform.");
}

SQDEBUGHOOK get debugHook => Pointer.fromFunction(_debugHook);

/// Holds the current line of each [SquirrelRunner] instance, used for debugging.
/// Assigns a [DebugLine] to each [SQVM] instance given.
Map<Pointer<SQVM>, DebugLine> debugLines = {};

void _debugHook(Pointer<SQVM> vm, int eventType, Pointer<Char> sourceFile,
    int sourceLine, Pointer<Char> funcName) {
  switch (String.fromCharCode(eventType)) {
    case 'l':
      debugLines[vm] = DebugLine(sourceFile.toDartString(), sourceLine,
          funcName: funcName.toDartString());
      break;
  }
}

/// Used for debugging.
/// This is called when a compile error occurs.
SQCOMPILERERROR get debugCompileHook => Pointer.fromFunction(_debugCompileHook);

/// Assigns a [DebugLine] to the [SQVM] instance given,
/// so developers can know where the compile error occurred.
void _debugCompileHook(Pointer<SQVM> vm, Pointer<Char> description,
    Pointer<Char> sourceFile, int sourceLine, int sourceColumn) {
  debugLines[vm] =
      DebugLine(sourceFile.toDartString(), sourceLine, column: sourceColumn);
}

final SquirrelBindings bindings = SquirrelBindings(_getDylib());

tagSQObjectType get sqInteger => tagSQObjectType.OT_INTEGER;

tagSQObjectType get sqFloat => tagSQObjectType.OT_FLOAT;

tagSQObjectType get sqBool => tagSQObjectType.OT_BOOL;

tagSQObjectType get sqString => tagSQObjectType.OT_STRING;

class SquirrelRunner {
  final Pointer<SQVM> vm;

  /// Returns the current [DebugLine] of the [SquirrelRunner] instance.
  /// Assigns a [DebugLine] to each [SQVM] instance given.
  DebugLine? get _debugLine => debugLines[vm];

  /// Creates a new [SquirrelRunner] instance.
  /// The initial stack size is set to 1024.
  SquirrelRunner() : vm = bindings.sq_open(1024);

  /// # `void` _createAPI(List<SquirrelFunction> apiFunctions)
  /// ## Creates the API for the Squirrel instance.
  /// It takes a list of [SquirrelFunction] objects and adds them to the global scope of the Squirrel instance.
  void createAPI(List<SquirrelFunction> apiFunctions,
      {String apiTableName = "arceus"}) {
    bindings.sq_pushroottable(vm); // Pushes the root table.
    bindings.sq_newtable(vm); // Creates a new table.
    for (SquirrelFunction func in apiFunctions) {
      // Adds the functions to the table.
      func.setInstance(this);
      bindings.sq_pushstring(vm, func.name.toCharPointer(), -1);
      bindings.sq_newclosure(
          vm,
          NativeCallable<LongLong Function(Pointer<SQVM> ctx)>.isolateLocal(
                  func.call,
                  exceptionalReturn: SQ_ERROR)
              .nativeFunction,
          0);
      bindings.sq_newslot(vm, -3, SQFalse);
    }
    bindings.sq_pushstring(vm, apiTableName.toCharPointer(),
        -1); // Adds the table to the global scope.
    bindings.sq_push(vm, -2); // Pushes the table.
    bindings.sq_remove(vm, -3); // Removes the table from the stack.
    bindings.sq_newslot(vm, -3, SQFalse); // Adds the table to the global scope.
    bindings.sq_pop(vm, 1); // Pops the table from the stack.
  }

  /// Returns the value from the stack, popping it if `noPop` is false.
  /// By default, [noPop] is false, and [idx] is -1 (i.e. the top of the stack).
  T? getStackValue<T>({int idx = -1, bool noPop = false}) {
    final result = bindings.sq_gettype(vm, idx);
    dynamic value;

    if (result == tagSQObjectType.OT_STRING) {
      final p = ffi.calloc<Pointer<Char>>();
      try {
        bindings.sq_getstring(
            vm, idx, p); // pass along the pointer to get the value.
        value = p.value.toDartString();
      } finally {
        ffi.calloc.free(p); // free memory
      }
    } else if (result == tagSQObjectType.OT_INTEGER) {
      final p = ffi.calloc<LongLong>();
      try {
        bindings.sq_getinteger(vm, idx, p);
        value = p.value;
      } finally {
        ffi.calloc.free(p);
      }
    } else if (result == tagSQObjectType.OT_FLOAT) {
      final p = ffi.calloc<Float>();
      try {
        bindings.sq_getfloat(vm, idx, p);
        value = p.value;
      } finally {
        ffi.calloc.free(p);
      }
    } else if (result == tagSQObjectType.OT_BOOL) {
      final p = ffi.calloc<UnsignedLongLong>();
      try {
        bindings.sq_getbool(vm, idx, p);
        value = p.value == 1 ? true : false;
      } finally {
        ffi.calloc.free(p);
      }
    } else if (result == tagSQObjectType.OT_ARRAY) {
      bindings.sq_pushnull(vm);
      value = [];
      while (bindings.sq_next(vm, -2) == 0) {
        (value as List).add(getStackValue(idx: -1, noPop: true));
        bindings.sq_pop(vm, 1);
      }
    } else if (result == tagSQObjectType.OT_TABLE) {
      bindings.sq_pushnull(vm);
      value = {};
      while (bindings.sq_next(vm, -2) == 0) {
        // print("Stack \n${getStackForPrint(vm)}");
        (value as Map).putIfAbsent(getStackValue(idx: -2, noPop: true),
            () => getStackValue(idx: -1, noPop: true));
        bindings.sq_pop(vm, 2);
      }
      if (bindings.sq_gettype(vm, -1) != tagSQObjectType.OT_TABLE) {
        bindings.sq_pop(vm, 1);
      }
    } else if (result == tagSQObjectType.OT_INSTANCE) {
      bindings.sq_pushroottable(vm);
      bindings.sq_pushstring(vm, "__export__".toCharPointer(), -1);
      bindings.sq_get(vm, -2);
      bindings.sq_pushroottable(vm);
      bindings.sq_push(vm, -4);
      bindings.sq_remove(vm, -4);
      successful(bindings.sq_call(vm, 2, SQTrue, SQTrue));
      value = getStackValue(idx: -1, noPop: true);
      bindings.sq_pop(vm, 2);
    } else if (result == tagSQObjectType.OT_NULL) {
      value = null;
    } else {
      // print("Unknown type: $result");
      value = null;
    }

    if (value is! T) {
      throw Exception(
          "Stack value is not of type $T! Stack value: $value Type: $result");
    }

    if (!noPop) {
      bindings.sq_pop(vm, 1);
    }
    return value;
  }

  /// Pushes a value to the stack.
  /// The value can be a String, int, double, bool, List, or null.
  void pushToStack(dynamic value, {Pointer<SQVM>? pointer}) {
    if (value is String) {
      bindings.sq_pushstring(vm, value.toCharPointer(), -1);
    } else if (value is int) {
      bindings.sq_pushinteger(vm, value);
    } else if (value is double) {
      bindings.sq_pushfloat(vm, value);
    } else if (value is bool) {
      bindings.sq_pushbool(vm, value ? 1 : 0);
    } else if (value is List<dynamic>) {
      bindings.sq_newarray(vm, 0);
      for (int i = 0; i < value.length; i++) {
        pushToStack(value[i]);
        if (bindings.sq_arrayappend(vm, -2) == SQ_ERROR) {
          bindings.sq_pop(vm, 1);
          break;
        }
      }
    } else {
      bindings.sq_pushnull(vm);
    }
  }

  /// It takes a code string, a function name, and a list of arguments.
  /// It compiles the code, calls the function, and returns the return value.
  dynamic run(String code,
      {String functionName = "main", List<dynamic> args = const []}) {
    bindings.sq_setnativedebughook(vm, debugHook);
    bindings.sq_enabledebuginfo(vm, SQTrue);
    compile(code);
    return call(functionName, args: args);
  }

  /// It takes a name, a map of arguments, and a function to call.
  /// The function is called with the arguments, and the return value is returned.
  dynamic call(String functionName, {List<dynamic> args = const []}) {
    bindings.sq_pushroottable(vm);
    bindings.sq_pushstring(
        vm, functionName.toCharPointer(), functionName.length);
    bindings.sq_get(vm, -2);
    bindings.sq_pushroottable(vm);
    for (dynamic arg in args) {
      pushToStack(arg);
    }
    successful(bindings.sq_call(vm, args.length + 1, SQTrue,
        SQTrue)); // Calls and checks if the call was successful.
    final returnValue = getStackValue(); // Returns the return value.
    bindings.sq_pop(vm, 2); // Pops the function and the root table.
    return returnValue;
  }

  /// Compiles code and adds it to the root table.
  /// Throws an exception if the compilation fails.
  void compile(String code, {String sourceName = "run.nut"}) {
    final pointer = code.toCharPointer();
    bindings.sq_setcompilererrorhandler(vm, debugCompileHook);
    successful(bindings.sq_compilebuffer(
        vm, pointer, code.length, sourceName.toCharPointer(), SQTrue));
    ffi.malloc.free(pointer);
    bindings.sq_pushroottable(vm);
    successful(bindings.sq_call(vm, 1, SQFalse, SQTrue));
    bindings.sq_collectgarbage(vm);
    bindings.sq_pop(vm, 1);
  }

  /// # `static` void dispose(Pointer<SQVM> vm)
  /// ## Closes the Squirrel instance.
  void dispose() {
    bindings.sq_close(vm);
  }

  /// Checks if the call passed in was successful.
  /// If [result] is not [SQ_OK], it throws an exception.
  void successful(int result) {
    if (result != SQ_OK) {
      bindings.sq_getlasterror(vm);
      final error = getStackValue();
      print(_debugLine!.toString());
      print(getStackForPrint());
      throw Exception(error);
    }
  }

  /// Returns the stack as a list of strings.
  /// Used for debugging.
  List<String> getStack({Pointer<SQVM>? pointer}) {
    List<String> stack = [];
    int i = bindings.sq_gettop(vm);
    while (i > 0) {
      bindings.sq_tostring(vm, i); // convert to string
      final p = ffi.calloc<Pointer<Char>>(); // create a pointer
      bindings.sq_getstring(vm, -1, p); // get the string
      stack.add(p.value.toDartString()); // add to the stack
      ffi.calloc.free(p); // free memory
      bindings.sq_pop(vm, 1); // pop
      i--; // decrement
    }
    return stack;
  }

  /// Returns the stack as a string.
  /// This formats the stack for printing. Used for debugging.
  String getStackForPrint({Pointer<SQVM>? pointer}) {
    final stack = getStack(pointer: vm);
    return stack.join("\n");
  }
}

class DebugLine {
  final int? column;
  final int line;
  final String? funcName;
  final String sourceFile;
  DebugLine(this.sourceFile, this.line, {this.column, this.funcName});
  @override
  String toString() {
    return "$sourceFile:$line${column != null ? ":$column" : ""} ${funcName ?? ""}";
  }
}

/// It takes a name, a map of arguments, and a function to call.
class SquirrelFunction {
  final String name;

  /// The arguments for the function.
  /// The avaible types you can use is [sqInteger], [sqFloat], [sqBool], and [sqString].
  /// Records can be used for optional arguments, in the format of (type, defaultValue).
  /// For example: ([sqInteger], 0)
  /// Optional arguments must be at the end of the list, to avoid skipping required arguments.
  final Map<String, dynamic> arguments;

  SquirrelRunner? _squirrel;

  /// Sets the instance of the [SquirrelRunner] class in the function.
  void setInstance(SquirrelRunner squirrel) {
    _squirrel = squirrel;
  }

  final dynamic Function(Map<String, dynamic> params) _call;

  SquirrelFunction(
    this.name,
    this.arguments,
    this._call,
  );

  int get nargs => arguments.entries.length;

  /// It attempts to get the parameters from the stack.
  /// To learn more, see [arguments].
  Map<String, dynamic> _getParams(SquirrelRunner squirrel) {
    Map<String, dynamic> params = {};
    // print(arguments.keys.toList().reversed);
    for (String key in arguments.keys.toList().reversed) {
      switch (arguments[key]) {
        case tagSQObjectType.OT_STRING:
          params[key] = squirrel.getStackValue<String>();
          break;
        case tagSQObjectType.OT_INTEGER:
          params[key] = squirrel.getStackValue<int>();
          break;
        case tagSQObjectType.OT_FLOAT:
          params[key] = squirrel.getStackValue<double>();
          break;
        case tagSQObjectType.OT_BOOL:
          params[key] = squirrel.getStackValue<bool>();
          break;
        default:
          if (arguments[key] is Map) {
            params[key] = arguments[key].cast<dynamic, dynamic>();
            Map? table = squirrel.getStackValue<Map<dynamic, dynamic>>();
            params[key].addAll(table);
          } else if (arguments[key] is (tagSQObjectType, dynamic)) {
            try {
              params[key] = squirrel.getStackValue();
            } catch (e) {
              throw ('Tried to use given record ${arguments[key]} as argument. Expected record must be (tagSQObjectType, dynamic)');
            }
          }
      }
    }
    return params;
  }

  /// Pushes the return value to the stack.
  void _returnValue(SquirrelRunner squirrel, dynamic value) {
    squirrel.pushToStack(value);
  }

  /// Calls the _call function with the given parameters from the [SquirrelRunner]
  /// instance and return its result back to Squirrel.
  int call(Pointer<SQVM> vm) {
    try {
      final result = _call(_getParams(_squirrel!));
      _returnValue(_squirrel!, result);
    } catch (e) {
      print(e);
    }
    return SQ_OK;
  }
}

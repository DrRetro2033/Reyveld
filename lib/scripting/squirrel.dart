import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/scripting/bindings.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

/// Gets the dynamic library for the squirrel bindings.
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

/// Used for debugging.
/// This is called when an error occurs.
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

Pointer<NativeFunction<Void Function(Pointer<SQVM>, Pointer<Char>)>>
    printSquirl = Pointer.fromFunction(_printSquirl);
void _printSquirl(Pointer<SQVM> vm, Pointer<Char> s) {
  print(s.toDartString());
  return;
}

final SquirrelBindings bindings = SquirrelBindings(_getDylib());

tagSQObjectType get sqInteger => tagSQObjectType.OT_INTEGER;

tagSQObjectType get sqFloat => tagSQObjectType.OT_FLOAT;

tagSQObjectType get sqBool => tagSQObjectType.OT_BOOL;

tagSQObjectType get sqString => tagSQObjectType.OT_STRING;

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

class SquirrelVM {
  final Pointer<SQVM> vm;
  SquirrelVM() : vm = bindings.sq_open(128) {
    bindings.sq_setprintfunc(vm, printSquirl, printSquirl);
    bindings.sq_setcompilererrorhandler(vm, debugCompileHook);
    bindings.sq_setnativedebughook(vm, debugHook);
    bindings.sq_enabledebuginfo(vm, SQTrue);
  }

  /// Returns the current [DebugLine] of the [SquirrelRunner] instance.
  /// Assigns a [DebugLine] to each [SQVM] instance given.
  DebugLine? get _debugLine => debugLines[vm];
  void _successful(int result) {
    if (result != SQ_OK) {
      bindings.sq_getlasterror(vm);
      final error = getStackValue();
      print(_debugLine!.toString());
      print(getStackForPrint());
      throw Exception(error);
    }
  }

  dynamic call(String name, {List<dynamic> args = const []}) {
    bindings.sq_pushroottable(vm);
    bindings.sq_pushstring(vm, name.toCharPointer(), -1);
    bindings.sq_get(vm, -2);
    bindings.sq_pushroottable(vm);
    for (dynamic arg in args) {
      pushStackValue(arg);
    }
    _successful(bindings.sq_call(vm, args.length + 1, SQTrue,
        SQTrue)); // Calls and checks if the call was successful.
    final returnValue = getStackValue(); // Returns the return value.
    bindings.sq_pop(vm, 2); // Pops the function and the root table.
    return returnValue;
  }

  /// Frees the memory associated with the [SquirrelVM] instance.
  /// This has to be called when the object is no longer used to prevent memory leaks.
  void dispose() {
    bindings.sq_close(vm);
    // debugLines.remove(vm);
  }

  void addScript(String script, {String name = "run.nut"}) {
    final scriptP = script.toCharPointer();
    final nameP = name.toCharPointer();
    bindings.sq_compilebuffer(vm, scriptP, script.length, nameP, SQTrue);
    bindings.sq_pushroottable(vm);
    _successful(bindings.sq_call(vm, 1, SQFalse, SQTrue));
    bindings.sq_collectgarbage(vm);
    bindings.sq_pop(vm, 1);
    ffi.malloc.free(scriptP);
    ffi.malloc.free(nameP);
  }

  /// Adds a table to the global scope with the given functions and variables.
  ///
  /// Functions are added with the name given in the [SAPIFunc.name] field.
  /// Variables are added with the name given in the [vars] map.
  ///
  /// The table is added to the global scope with the given [name].
  void addAPITable(
      {List<SAPIFunc> funcs = const [],
      String name = "arceus",
      Map<String, dynamic> vars = const {}}) {
    bindings.sq_pushroottable(vm); // Pushes the root table.
    bindings.sq_newtable(vm); // Creates a new table.
    for (SAPIFunc func in funcs) {
      // Adds the functions to the table.
      final nameP = func.name.toCharPointer();
      func.setInstance(this);
      bindings.sq_pushstring(vm, nameP, -1);
      bindings.sq_newclosure(
          vm,
          NativeCallable<LongLong Function(Pointer<SQVM> ctx)>.isolateLocal(
                  func.call,
                  exceptionalReturn: SQ_ERROR)
              .nativeFunction,
          0);
      bindings.sq_newslot(vm, -3, SQTrue);
      ffi.malloc.free(nameP);
    }
    for (String key in vars.keys) {
      // Adds the variables to the table.
      final nameP = key.toCharPointer();
      bindings.sq_pushstring(vm, nameP, -1);
      pushStackValue(vars[key]);
      bindings.sq_newslot(vm, -3, SQTrue);
      ffi.malloc.free(nameP);
    }
    final nameP = name.toCharPointer();
    bindings.sq_pushstring(
        vm, nameP, -1); // Adds the table to the global scope.
    bindings.sq_push(vm, -2); // Pushes the table.
    bindings.sq_remove(vm, -3); // Removes the table from the stack.
    bindings.sq_newslot(vm, -3, SQTrue); // Adds the table to the global scope.
    bindings.sq_pop(vm, 1); // Pops the table from the stack.
    ffi.malloc.free(nameP);
  }

  /// Returns the value at the at [idx] position in the stack.
  /// If [pop] is true, the value will be popped from the stack.
  /// If [requiredType] is specified, then if the value is not of that type, null will be returned.
  /// Throws an exception if the value is not of the required type defined in [T].
  T? getStackValue<T>(
      {int idx = -1, bool pop = true, tagSQObjectType? requiredType}) {
    final type = bindings.sq_gettype(vm, idx);
    dynamic value;

    if (requiredType != null && type != requiredType) {
      return null;
    }

    if (type == tagSQObjectType.OT_STRING) {
      final p = ffi.calloc<Pointer<Char>>();
      try {
        bindings.sq_getstring(
            vm, idx, p); // pass along the pointer to get the value.
        value = p.value.toDartString();
      } finally {
        ffi.calloc.free(p); // free memory
      }
    } else if (type == tagSQObjectType.OT_INTEGER) {
      final p = ffi.calloc<LongLong>();
      try {
        bindings.sq_getinteger(vm, idx, p);
        value = p.value;
      } finally {
        ffi.calloc.free(p);
      }
    } else if (type == tagSQObjectType.OT_FLOAT) {
      final p = ffi.calloc<Float>();
      try {
        bindings.sq_getfloat(vm, idx, p);
        value = p.value;
      } finally {
        ffi.calloc.free(p);
      }
    } else if (type == tagSQObjectType.OT_BOOL) {
      final p = ffi.calloc<UnsignedLongLong>();
      try {
        bindings.sq_getbool(vm, idx, p);
        value = p.value == 1 ? true : false;
      } finally {
        ffi.calloc.free(p);
      }
    } else if (type == tagSQObjectType.OT_ARRAY) {
      bindings.sq_pushnull(vm);
      value = [];
      while (bindings.sq_next(vm, -2) == 0) {
        (value as List).add(getStackValue(idx: -1, pop: false));
        bindings.sq_pop(vm, 1);
      }
    } else if (type == tagSQObjectType.OT_TABLE) {
      bindings.sq_pushnull(vm);
      value = {};
      while (bindings.sq_next(vm, -2) == 0) {
        // print("Stack \n${getStackForPrint(vm)}");
        (value as Map).putIfAbsent(getStackValue(idx: -2, pop: false),
            () => getStackValue(idx: -1, pop: false));
        bindings.sq_pop(vm, 2);
      }
      if (bindings.sq_gettype(vm, -1) != tagSQObjectType.OT_TABLE) {
        bindings.sq_pop(vm, 1);
      }
    } else if (type == tagSQObjectType.OT_INSTANCE) {
      bindings.sq_pushroottable(vm);
      bindings.sq_pushstring(vm, "__export__".toCharPointer(), -1);
      bindings.sq_get(vm, -2);
      bindings.sq_pushroottable(vm);
      bindings.sq_push(vm, -4);
      bindings.sq_remove(vm, -4);
      _successful(bindings.sq_call(vm, 2, SQTrue, SQTrue));
      value = getStackValue(idx: -1, pop: false);
      bindings.sq_pop(vm, 2);
    } else if (type == tagSQObjectType.OT_NULL) {
      value = null;
    } else {
      value = null;
    }

    if (value is! T) {
      throw Exception(
          "Stack value is not of type $T! Stack value: $value Type: $type");
    }

    if (pop) {
      bindings.sq_pop(vm, 1);
    }
    return value;
  }

  /// Pushes the given [value] to the stack of the Squirrel VM.
  /// It will be converted to a Squirrel value according to the following rules:
  ///
  /// - Strings are converted to Squirrel strings.
  /// - Ints are converted to Squirrel integers.
  /// - Doubles are converted to Squirrel floats.
  /// - Booleans are converted to Squirrel booleans.
  /// - Lists are converted to Squirrel tables.
  /// - Maps are converted to Squirrel tables.
  /// - All other types are converted to Squirrel null.
  void pushStackValue(dynamic value) {
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
        pushStackValue(value[i]);
        if (bindings.sq_arrayappend(vm, -2) == SQ_ERROR) {
          bindings.sq_pop(vm, 1);
          break;
        }
      }
    } else {
      bindings.sq_pushnull(vm);
    }
  }

  /// Returns the stack as a list of strings.
  /// Used for debugging.
  List<String> getStack() {
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
  String getStackForPrint() {
    final stack = getStack();
    return stack.join("\n");
  }

  void printStack() {
    print(getStackForPrint());
  }
}

class SAPIFunc<T> {
  final String name;
  final Map<String, dynamic> args;
  final T Function(Map<String, dynamic> params, dynamic context) _call;

  /// The context of the function. (e.g. a file instance)
  /// Will be passed to the function as the second argument of the call.
  final dynamic context;

  /// Whether the function returns a value.
  final bool returnsValue;

  /// The squirrel instance.
  SquirrelVM? squirrel;

  /// Sets the squirrel instance.
  void setInstance(SquirrelVM vm) => squirrel = vm;

  SAPIFunc(this.name, this.args, this._call,
      {this.returnsValue = true, this.context});

  /// Given a set of arguments, pops the required values from the stack and
  /// creates a map of the given parameters.
  ///
  /// The arguments map should have the following structure:
  ///
  /// - key: the name of the parameter
  /// - value: the type of the parameter, which can be one of the following:
  ///   - [sqInteger]
  ///   - [sqFloat]
  ///   - [sqBool]
  ///   - [sqString]
  ///   - A map with the following structure:
  ///     - key: the name of a subparameter
  ///     - value: the type or a tuple
  ///   - A tuple with the following structure defines a default value:
  ///     - item 1: the type of the parameter
  ///     - item 2: the default value
  ///
  /// If the type is a table, the table is retrieved from the stack and added
  /// to the default map. If the type is a tuple, the value is retrieved from
  /// the stack and if it is null, the default value is used.
  ///
  /// This method is used to pass arguments to squirrel functions.
  Map<String, dynamic> _getParams(Pointer<SQVM> vm) {
    Map<String, dynamic> params = {};
    // print(arguments.keys.toList().reversed);
    for (String key in args.keys.toList().reversed) {
      switch (args[key]) {
        case tagSQObjectType.OT_STRING:
          params[key] = squirrel!.getStackValue<String>();
          break;
        case tagSQObjectType.OT_INTEGER:
          params[key] = squirrel!.getStackValue<int>();
          break;
        case tagSQObjectType.OT_FLOAT:
          params[key] = squirrel!.getStackValue<double>();
          break;
        case tagSQObjectType.OT_BOOL:
          params[key] = squirrel!.getStackValue<bool>();
          break;
        default:
          if (args[key] is Map) {
            params[key] = args[key].cast<dynamic, dynamic>();
            Map? table = squirrel!.getStackValue<Map<dynamic, dynamic>>();
            params[key].addAll(table);
          } else if (args[key] is (tagSQObjectType, dynamic)) {
            try {
              final param = squirrel!.getStackValue(requiredType: args[key].$1);
              params[key] = param ?? args[key].$2;
            } catch (e) {
              throw ('Tried to use given record ${args[key]} as argument. Expected record must be (tagSQObjectType, dynamic)');
            }
          }
      }
    }
    return params;
  }

  int call(Pointer<SQVM> vm) {
    try {
      final result = _call(_getParams(vm), context);
      squirrel!.pushStackValue(result);
    } catch (e) {
      print(e);
    }
    return returnsValue ? 1 : 0;
  }
}

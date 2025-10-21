part of 'package:reyveld/builder.dart';

class SInterfaceGenerator extends GeneratorForAnnotation<LuaClass> {
  @override
  String generateForAnnotatedElement(
      Element2 element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        '@LuaClass can only be used on classes.',
        element: element,
      );
    }
    final className = element.name3!;
    final interfaceClassname = '${className}Interface';
    final name = annotation.peek("name")?.stringValue ?? className;
    final description = annotation.read("description").stringValue;

    final extendingClass =
        element.thisType.superclass?.element3.metadata2.annotations.any((meta) {
                  final obj = meta.computeConstantValue();
                  return obj?.type?.getDisplayString() == 'LuaClass';
                }) ??
                false
            ? element.thisType.superclass?.element3
            : null;

    final methods = element.methods2.where((method) {
      return method.metadata2.annotations.any((meta) {
        final obj = meta.computeConstantValue();
        return obj?.type?.getDisplayString() == 'LuaExport';
      });
    }).toList();
    final getters = element.getters2.where((method) {
      return method.metadata2.annotations.any((meta) {
        final obj = meta.computeConstantValue();
        return obj?.type?.getDisplayString() == 'LuaExport';
      });
    });
    final entrypoints = <ExportGen>[];

    /// Generate the methods with the LuaFunc annotation.
    for (final method in methods) {
      /// Get the annotation.
      final annotation = ConstantReader(method.metadata2.annotations
          .where((meta) {
            final obj = meta.computeConstantValue();
            return obj?.type?.getDisplayString() == 'LuaExport';
          })
          .singleOrNull!
          .computeConstantValue());
      final funcName = annotation.peek("name")?.stringValue ?? method.name3!;
      final funcDescription = annotation.peek("description")!.stringValue;
      final funcSecurityCheck = annotation
          .peek("securityCheck")
          ?.objectValue
          .variable2
          ?.displayString2();
      final funcIsStatic = method.isStatic;
      final funcIsAync = method.returnType.isDartAsyncFuture ||
          method.returnType.isDartAsyncFutureOr;
      final funcNullable =
          method.returnType.nullabilitySuffix == NullabilitySuffix.question;
      final args = method.formalParameters;
      final funcPassLua = args.where((arg) {
        return arg.type.getDisplayString() == 'Lua';
      });
      final funcPassLuaState = args.where((arg) {
        return arg.type.getDisplayString() == 'LuaState';
      });
      final funcArgs = args.where((arg) {
        return arg.type.getDisplayString() != 'Lua' &&
            arg.type.getDisplayString() != 'LuaState';
      }).map((arg) {
        ArgKind kind = arg.isOptional
            ? ArgKind.optionalPositional
            : ArgKind.requiredPositional;
        if (arg.isNamed) {
          kind = arg.isOptional ? ArgKind.optionalNamed : ArgKind.requiredNamed;
        }
        String? defaultValue;
        if (arg.constantInitializer2 != null) {
          defaultValue = arg.constantInitializer2!.expression.toString();
        }
        return (
          arg.type.getDisplayString().replaceFirst("?", ""),
          arg.name3!,
          kind,
          defaultValue,
        );
      });
      String funcReturnType = method.returnType.getDisplayString();
      final genericRegex = RegExp(r"(\w*)<(.*)>");
      while (genericRegex.hasMatch(funcReturnType)) {
        final match = genericRegex.firstMatch(funcReturnType)!;
        if (match.group(1) == "Future") {
          funcReturnType = match.group(2)!;
        } else if (["Stream", "Iterable", "List", "Map"]
            .contains(match.group(1))) {
          funcReturnType = match.group(1)!;
        } else {
          break;
        }
      }
      funcReturnType = funcReturnType.replaceFirst("?", "");
      entrypoints.add(ExportGen(
        name: funcName,
        description: funcDescription,
        isStatic: funcIsStatic,
        isNullable: funcNullable,
        securityCheck: funcSecurityCheck,
        isAsync: funcIsAync,
        passLua: funcPassLua.isNotEmpty,
        passLuaState: funcPassLuaState.isNotEmpty,
        returnType: funcReturnType,
        args: funcArgs,
        actualFunc: method.name3!,
      ));
    }

    for (final getter in getters) {
      final annotation = ConstantReader(getter.metadata2.annotations
          .where((meta) {
            final obj = meta.computeConstantValue();
            return obj?.type?.getDisplayString() == 'LuaExport';
          })
          .singleOrNull!
          .computeConstantValue());
      final funcName = annotation.peek("name")?.stringValue ?? getter.name3!;
      final funcDescription = annotation.peek("description")!.stringValue;
      final funcSecurityCheck = annotation
          .peek("securityCheck")
          ?.objectValue
          .variable2
          ?.displayString2();
      final funcIsStatic = getter.isStatic;
      final funcNullable =
          getter.returnType.nullabilitySuffix == NullabilitySuffix.question;
      final funcReturnType = getter.returnType.getDisplayString();

      entrypoints.add(ExportGen(
        exportType: ExportType.gettersetter,
        name: funcName,
        description: funcDescription,
        isStatic: funcIsStatic,
        isNullable: funcNullable,
        securityCheck: funcSecurityCheck,
        isAsync: false,
        passLua: false,
        passLuaState: false,
        returnType: funcReturnType,
        args: getter.correspondingSetter2 != null
            ? [
                (
                  getter.returnType.getDisplayString(),
                  "value",
                  ArgKind.optionalPositional,
                  null
                )
              ]
            : [],
        actualFunc: getter.name3!,
      ));
    }

    return '''
class $interfaceClassname extends SInterface<$className> {
  @override
  get className => "$name";

  @override
  get classDescription => """$description""";
  ${extendingClass != null ? "@override\nget parent => ${extendingClass.name3}Interface();" : ""}

  @override
  get statics => {
    ${entrypoints.where((e) => e.isStatic).map((e) => e.toLEntry(className)).join(", ")}
  };

  @override
  get exports => {
    ${entrypoints.where((e) => !e.isStatic).map((e) => e.toLEntry(className)).join(", ")}
  };
}
''';
  }
}

enum ExportType {
  method,
  gettersetter,
}

final class ExportGen {
  final String name;
  final String description;
  final String returnType;
  final bool isNullable;
  final bool isStatic;
  final bool isAsync;
  final bool passLua;
  final bool passLuaState;
  final ExportType exportType;
  final Iterable<(String, String, ArgKind, String?)> args;
  final String? securityCheck;
  final String actualFunc;
  bool get hasNamedArgs => args.any(
      (e) => e.$3 == ArgKind.optionalNamed || e.$3 == ArgKind.requiredNamed);
  bool get hasPositionalOptionalArgs =>
      args.any((e) => e.$3 == ArgKind.optionalPositional);

  const ExportGen({
    required this.name,
    required this.description,
    required this.returnType,
    required this.isNullable,
    required this.isStatic,
    required this.passLua,
    required this.passLuaState,
    required this.args,
    this.securityCheck,
    this.exportType = ExportType.method,
    required this.isAsync,
    required this.actualFunc,
  });

  String toLEntry(String className) => """LEntry(
    name: "$name", 
    descr: \"\"\"$description\"\"\",
    ${returnType != "void" ? "returnType: $returnType," : ""} 
    returnNullable: $isNullable,${_convertDartTypeToLua(returnType) != returnType ? "docReturnTypeOverride: \"${_convertDartTypeToLua(returnType)}\"," : ""}
    isAsync: $isAsync,
    passLua: $passLua,
    passState: $passLuaState,
    securityCheck: ${securityCheck?.toString() ?? "null"},
    ${_args()}
    ${_func(isStatic ? className : "object!")}
    )""";

  String _convertDartTypeToLua(String dartType) {
    final genericRegex = RegExp(r"(\w*)<(.*)>");
    final match = genericRegex.firstMatch(dartType);
    switch (match?.group(1)) {
      case "Future":
        return _convertDartTypeToLua(match!.group(2)!);
      case "List":
        return "${_convertDartTypeToLua(match!.group(2)!)}[]";
      case "Stream":
        return "Stream";
      case "Map":
        final types = match!.group(2)!.split(",");
        return "table<${_convertDartTypeToLua(types[0])},${_convertDartTypeToLua(types[1])}>";
      default:
        if (dartType == "String") {
          return "string";
        } else if (dartType == "int") {
          return "integer";
        } else if (dartType == "bool") {
          return "boolean";
        } else if (dartType == "double") {
          return "number";
        } else if (dartType == "List") {
          return "List";
        } else if (dartType == "Map") {
          return "table";
        } else if (dartType == "Object") {
          return "any";
        } else if (dartType == "LuaFuncRef") {
          return "function";
        } else {
          return dartType;
        }
    }
  }

  String _args() =>
      "args: const {${args.map((e) => """LArg<${e.$1}>(name: "${e.$2}", kind: ${e.$3}${_convertDartTypeToLua(e.$1) != e.$1 ? ", docTypeOverride: \"${_convertDartTypeToLua(e.$1)}\"" : ""}${e.$4 != null ? ", docDefaultValue: \"${e.$4}\"" : ""})""").join(", ")}},";

  String _func(String thing) =>
      "(${_funcParamters()})${isAsync ? " async" : ""} {${_body(thing)}}";

  String _body(String thing) {
    switch (exportType) {
      case ExportType.method:
        return """return $thing.$actualFunc(${passLua ? "lua, " : ""}${passLuaState ? "state, " : ""}${args.map((e) {
              if (e.$3 == ArgKind.requiredPositional ||
                  e.$3 == ArgKind.optionalPositional) {
                return e.$2;
              } else if (e.$3 == ArgKind.requiredNamed ||
                  e.$3 == ArgKind.optionalNamed) {
                return "${e.$2}: ${e.$2}";
              }
            }).cast<String>().join(", ")});""";
      case ExportType.gettersetter:
        if (args.isNotEmpty) {
          return """if (value != null) {
            $thing.$actualFunc = value;
          }
          return $thing.$actualFunc;
          """;
        }
        return """return $thing.$actualFunc;""";
    }
  }

  String _funcParamters() =>
      "${passLua ? "Lua lua, " : ""}${passLuaState ? "LuaState state, " : ""}${[
        ...args
            .where((e) => e.$3 == ArgKind.requiredPositional)
            .map((e) => "${e.$1} ${e.$2}"),
        hasPositionalOptionalArgs
            ? "[${args.where((e) => e.$3 == ArgKind.optionalPositional).map((e) => "${e.$1}${e.$4 == null ? "?" : ""} ${e.$2}${e.$4 != null ? " = ${e.$4}" : ""}").join(", ")}]"
            : null,
        hasNamedArgs
            ? "{${args.where((e) => e.$3 == ArgKind.requiredNamed || e.$3 == ArgKind.optionalNamed).map((e) => "${e.$1}${e.$4 == null ? "?" : ""} ${e.$2}${e.$4 != null ? " = ${e.$4}" : ""}").join(", ")}}"
            : null,
      ].where((e) => e != null).join(", ")}";
}

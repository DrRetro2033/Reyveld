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
    final className = element.name3;
    final interfaceClassname = '${className}Interface';
    final name = annotation.peek("name")?.stringValue ?? className;
    final description = annotation.peek("description")?.stringValue;

    final methods = element.methods2.where((method) {
      return method.metadata2.annotations.any((meta) {
        final obj = meta.computeConstantValue();
        return obj?.type?.getDisplayString() == 'LuaFunc';
      });
    }).toList();
    final entrypoints = [];
    for (final method in methods) {
      final annotation = ConstantReader(method.metadata2.annotations
          .where((meta) {
            final obj = meta.computeConstantValue();
            return obj?.type?.getDisplayString() == 'LuaFunc';
          })
          .singleOrNull!
          .computeConstantValue());
      final funcName = annotation.peek("name")?.stringValue ?? method.name3;
      final funcDescription = annotation.peek("description")?.stringValue;
      final funcSecurityCheck = annotation.peek("securityCheck")?.toString();
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
        return (
          arg.type.getDisplayString().replaceFirst("?", ""),
          arg.name3!,
          kind
        );
      });
      String funcReturnType = method.returnType.getDisplayString();
      final genericRegex = RegExp(r"<(.*)>");
      while (funcReturnType.contains(genericRegex)) {
        funcReturnType = genericRegex.firstMatch(funcReturnType)!.group(1)!;
      }
      funcReturnType = funcReturnType.replaceFirst("?", "");
      entrypoints.add({
        "name": funcName,
        "description": funcDescription,
        "isStatic": funcIsStatic,
        "isNullable": funcNullable,
        "securityCheck": funcSecurityCheck,
        "funcIsAync": funcIsAync,
        "funcPassLua": funcPassLua.isNotEmpty,
        "funcPassLuaState": funcPassLuaState.isNotEmpty,
        "returnType": funcReturnType,
        "args": funcArgs,
        "func": method.name3,
      });
    }

    return '''
class $interfaceClassname extends SInterface<$className> {
  @override
  get className => "$name";

  @override
  get classDescription => "$description";

  @override
  get statics => {
    ${entrypoints.where((e) => e["isStatic"]).map((e) => """LEntry(
    name: "${e["name"]}", 
    descr: "${e["description"]}",
    returnType: ${e["returnType"]}, 
    returnNullable: ${e["isNullable"]}, 
    isAsync: ${e["funcIsAync"]},
    passLua: ${e["funcPassLua"]},
    passState: ${e["funcPassLuaState"]},
    securityCheck: ${e["securityCheck"]},
    args: const {${(e["args"] as Iterable<(
                  String,
                  String,
                  ArgKind
                )>).map((e) => """LArg<${e.$1}>(name: "${e.$2}", kind: ${e.$3})""").join(", ")}},
    (${e["funcPassLua"] ? "Lua lua, " : ""}${e["funcPassLuaState"] ? "LuaState state, " : ""}${e["args"].map((e) => "${e.$1} ${e.$2}").join(", ")})${e["funcIsAync"] ? " async" : ""} => $className.${e["func"]}(${e["funcPassLua"] ? "lua, " : ""}${e["funcPassLuaState"] ? "state, " : ""}${e["args"].map((e) => e.$2)})
    )""").join(", ")}
  };

  @override
  get exports => {
    ${entrypoints.where((e) => !e["isStatic"]).map((e) => """LEntry(
    name: "${e["name"]}", 
    descr: "${e["description"]}",
    returnType: ${e["returnType"]}, 
    returnNullable: ${e["isNullable"]}, 
    isAsync: ${e["funcIsAync"]},
    passLua: ${e["funcPassLua"]},
    passState: ${e["funcPassLuaState"]},
    securityCheck: ${e["securityCheck"]},
    args: const {${(e["args"] as Iterable<(
                  String,
                  String,
                  ArgKind
                )>).map((e) => """LArg<${e.$1}>(name: "${e.$2}", kind: ${e.$3}""").join(", ")}},
    (${e["funcPassLua"] ? "Lua lua, " : ""}${e["funcPassLuaState"] ? "LuaState state, " : ""}, ${e["args"].map((e) => "${e.$1} ${e.$2}").join(", ")})${e["funcIsAync"] ? " async" : ""} => object!.${e["func"]}(${e["funcPassLua"] ? "lua, " : ""}${e["funcPassLuaState"] ? "state, " : ""} ${e["args"].map((e) => e.$2)})""").join(", ")}
  };
}
''';
  }
}

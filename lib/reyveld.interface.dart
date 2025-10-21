// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'reyveld.dart';

// **************************************************************************
// SInterfaceGenerator
// **************************************************************************

class ReyveldInterface extends SInterface<Reyveld> {
  @override
  get className => "Reyveld";

  @override
  get classDescription =>
      """Contains global functions for Reyveld, for example, settings, paths, etc.""";

  @override
  get statics => {
        LEntry(
            name: "getPerformanceOption",
            descr: """Get a performance option.""",
            returnType: String,
            returnNullable: false,
            docReturnTypeOverride: "string",
            isAsync: true,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "option",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string")
            }, (String option) async {
          return Reyveld.getPerformanceOption(option);
        }),
        LEntry(
            name: "sinterfaceTest",
            descr: """Hello World!""",
            returnType: Map,
            returnNullable: false,
            docReturnTypeOverride: "table",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "hello",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<int>(
                  name: "a",
                  kind: ArgKind.optionalNamed,
                  docTypeOverride: "integer",
                  docDefaultValue: "0"),
              LArg<int>(
                  name: "b",
                  kind: ArgKind.optionalNamed,
                  docTypeOverride: "integer",
                  docDefaultValue: "2")
            }, (String hello, {int a = 0, int b = 2}) {
          return Reyveld.sinterfaceTest(hello, a: 0, b: 2);
        })
      };

  @override
  get exports => {};
}

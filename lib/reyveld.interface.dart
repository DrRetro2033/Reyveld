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
      };

  @override
  get exports => {};
}

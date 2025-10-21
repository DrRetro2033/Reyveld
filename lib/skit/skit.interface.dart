// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skit.dart';

// **************************************************************************
// SInterfaceGenerator
// **************************************************************************

class SKitInterface extends SInterface<SKit> {
  @override
  get className => "SKit";

  @override
  get classDescription =>
      """SKits are the file format used by Reyveld to store data in a sort of database format.""";

  @override
  get statics => {
        LEntry(
            name: "open",
            descr: """Opens a kit file.""",
            returnType: SKit,
            returnNullable: false,
            isAsync: true,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "path",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<SKitType>(name: "type", kind: ArgKind.optionalNamed),
              LArg<String>(
                  name: "encryptKey",
                  kind: ArgKind.optionalNamed,
                  docTypeOverride: "string",
                  docDefaultValue: "Arceus")
            }, (String path,
                {SKitType? type, String encryptKey = "Arceus"}) async {
          return SKit.open(path, type: null, encryptKey: "Arceus");
        })
      };

  @override
  get exports => {
        LEntry(
            name: "author",
            descr: """The [SAuthor](lua://SAuthor) of the kit file.""",
            returnType: Future<SAuthor>,
            returnNullable: false,
            docReturnTypeOverride: "SAuthor",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.author;
        })
      };
}

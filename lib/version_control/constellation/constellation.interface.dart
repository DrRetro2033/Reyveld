// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'constellation.dart';

// **************************************************************************
// SInterfaceGenerator
// **************************************************************************

class ConstellationInterface extends SInterface<Constellation> {
  @override
  get className => "Constellation";

  @override
  get classDescription =>
      """This class represents a constellation in a kit file.

A constellation is a collection of [Star](lua://Star)s, which describes the history of a folder.""";
  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
            name: "new",
            descr: """Creates a new constellation.""",
            returnType: Constellation,
            isAsync: true,
            args: const {
              LArg<String>(
                  name: "name", descr: "The name of the constellation."),
              LArg<String>(
                  name: "path", descr: "The tracked path of the constellation.")
            },
            (String name, String path) =>
                ConstellationCreator.start(name, path))
      };

  @override
  get exports => {
        LEntry(
            name: "name",
            descr: """The name of the constellation.""",
            returnType: String,
            returnNullable: false,
            docReturnTypeOverride: "string",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "value",
                  kind: ArgKind.optionalPositional,
                  docTypeOverride: "string")
            }, ([String? value]) {
          if (value != null) {
            object!.name = value;
          }
          return object!.name;
        }),
        LEntry(
            name: "path",
            descr: """The tracked path of the constellation.""",
            returnType: String,
            () => object!.path),
        LEntry(
            name: "root",
            descr: """The root star of the constellation.""",
            returnType: Star,
            () => object!.root),
        LEntry(
            name: "starByID",
            descr: """Gets a star by its id.""",
            returnType: Star,
            returnNullable: true,
            args: const {LArg<String>(name: "id")},
            (String id) => object!.getStarByID(id)),
      };
}

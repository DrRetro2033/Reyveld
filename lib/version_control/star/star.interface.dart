// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'star.dart';

// **************************************************************************
// SInterfaceGenerator
// **************************************************************************

class StarInterface extends SInterface<Star> {
  @override
  get className => "Star";

  @override
  get classDescription => """This class represents a star in a constellation.
A star is a point in time that represents a snapshot of an folder.""";
  @override
  get parent => SObjectInterface();

  @override
  get statics => {};

  @override
  get exports => {
        LEntry(
            name: "anchor",
            descr: """Anchors the star, making it the stem of a new branch.""",
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "name",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string")
            }, (String name) {
          return object!.makeStem(name);
        }),
        LEntry(
            name: "unanchor",
            descr: """Unanchors the star.""",
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.unmakeStem();
        }),
        LEntry(
            name: "grow",
            descr: """Grows a new star from this star.""",
            returnType: Star,
            returnNullable: false,
            isAsync: true,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "name",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string"),
              LArg<String>(
                  name: "branchName",
                  kind: ArgKind.optionalNamed,
                  docTypeOverride: "string")
            }, (String name, {String? branchName}) async {
          return object!.grow(name, branchName: null);
        }),
        LEntry(
            name: "trim",
            descr: """Trims a star from the constellation.""",
            returnNullable: false,
            isAsync: true,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () async {
          return object!.trim();
        }),
        LEntry(
            name: "summary",
            descr: """Gets a summary of the star.""",
            returnType: Map,
            returnNullable: false,
            docReturnTypeOverride: "table",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.summary();
        }),
        LEntry(
            name: "makeCurrent",
            descr: """Makes this star the current star.""",
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.makeCurrent();
        }),
        LEntry(
            name: "checkout",
            descr:
                """Extracts the contents of this star, without needing to make it the current star.""",
            returnType: Stream,
            returnNullable: false,
            isAsync: true,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<String>(
                  name: "path",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string")
            }, (String path) async {
          return object!.checkout(path);
        }),
        LEntry(
            name: "checkForChanges",
            descr: """Checks for changes from the current star.

Will return true if there are changes, false if there are none.""",
            returnType: bool,
            returnNullable: false,
            docReturnTypeOverride: "boolean",
            isAsync: true,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () async {
          return object!.checkForChanges();
        }),
        LEntry(
            name: "foward",
            descr:
                """Gets the star forward to this star X times, also known as children/descendants.
      
When encountering a fork, the top most star will be chosen.""",
            returnType: Star,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<int>(
                  name: "x",
                  kind: ArgKind.optionalPositional,
                  docTypeOverride: "integer",
                  docDefaultValue: "1")
            }, ([int x = 1]) {
          return object!.foward(x);
        }),
        LEntry(
            name: "backward",
            descr:
                """Gets the star backward to this star X times, also known as parents/ancestors.""",
            returnType: Star,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<int>(
                  name: "x",
                  kind: ArgKind.optionalPositional,
                  docTypeOverride: "integer",
                  docDefaultValue: "1")
            }, ([int x = 1]) {
          return object!.backward(x);
        }),
        LEntry(
            name: "above",
            descr:
                """Gets the star above this star X times, also known as siblings.""",
            returnType: Star,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<int>(
                  name: "x",
                  kind: ArgKind.optionalPositional,
                  docTypeOverride: "integer",
                  docDefaultValue: "1")
            }, ([int x = 1]) {
          return object!.above(x);
        }),
        LEntry(
            name: "below",
            descr:
                """Gets the star below this star X times, also known as siblings.""",
            returnType: Star,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<int>(
                  name: "x",
                  kind: ArgKind.optionalPositional,
                  docTypeOverride: "integer",
                  docDefaultValue: "1")
            }, ([int x = 1]) {
          return object!.below(x);
        }),
        LEntry(
            name: "next",
            descr: """Gets the child star at position X.
  
Will wrap around to the top if X is greater than the number of children.""",
            returnType: Star,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {
              LArg<int>(
                  name: "x",
                  kind: ArgKind.optionalPositional,
                  docTypeOverride: "integer",
                  docDefaultValue: "1")
            }, ([int x = 1]) {
          return object!.next(x);
        }),
        LEntry(
            name: "recent",
            descr: """Gets the most recent descendant star.""",
            returnType: Star,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.recent();
        }),
        LEntry(
            name: "name",
            descr: """The name of the star.""",
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
            name: "archive",
            descr: """The archive of the star.""",
            returnType: Future<SArchive?>,
            returnNullable: false,
            docReturnTypeOverride: "SArchive?",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.archive;
        }),
        LEntry(
            name: "createdOn",
            descr: """The date the star was created.""",
            returnType: DateTime,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.createdOn;
        }),
        LEntry(
            name: "constellation",
            descr: """The constellation of the star.""",
            returnType: Constellation,
            returnNullable: false,
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.constellation;
        }),
        LEntry(
            name: "isRoot",
            descr: """True if the star is the root star.""",
            returnType: bool,
            returnNullable: false,
            docReturnTypeOverride: "boolean",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.isRoot;
        }),
        LEntry(
            name: "isCurrent",
            descr: """True if the star is the current star.""",
            returnType: bool,
            returnNullable: false,
            docReturnTypeOverride: "boolean",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.isCurrent;
        }),
        LEntry(
            name: "isSingleChild",
            descr: """True if the star is a single child.""",
            returnType: bool,
            returnNullable: false,
            docReturnTypeOverride: "boolean",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.isSingleChild;
        }),
        LEntry(
            name: "isLeaf",
            descr: """True if the star is a leaf.""",
            returnType: bool,
            returnNullable: false,
            docReturnTypeOverride: "boolean",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.isLeaf;
        }),
        LEntry(
            name: "isStem",
            descr: """True if the star is the stem of a branch.""",
            returnType: bool,
            returnNullable: false,
            docReturnTypeOverride: "boolean",
            isAsync: false,
            passLua: false,
            passState: false,
            securityCheck: null,
            args: const {}, () {
          return object!.isStem;
        })
      };
}

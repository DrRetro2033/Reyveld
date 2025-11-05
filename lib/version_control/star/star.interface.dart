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
            name: "archive",
            descr: """The archive of this star.""",
            returnType: SArchive,
            () => object!.archive),
        LEntry(
            name: "anchor",
            descr: """Anchors the star, making it the stem of a new branch.""",
            args: const {
              LArg<String>(
                  name: "name",
                  kind: ArgKind.requiredPositional,
                  docTypeOverride: "string")
            }, (String name) {
          return object!.makeStem(name);
        }),
        LEntry(name: "unanchor", descr: """Unanchors the star.""", () {
          return object!.unmakeStem();
        }),
        LEntry(
            name: "grow",
            descr: """Grows a new star from this star.""",
            returnType: Star,
            isAsync: true,
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
            isAsync: true, () async {
          return object!.trim();
        }),
        LEntry(
            name: "summary",
            descr:
                """Gets a detailed summary of the star (without any descendants).

If you need a more detailed tree view (including descendants), use the [tree](lua://Star.tree) method instead.""",
            returnType: Map, () {
          return object!.summary();
        }),
        LEntry(
            name: "tree",
            descr:
                """Gets a detailed tree view from the star (including descendants).

If you only need only a summary (without any descendants), use the [summary](lua://Star.summary) method instead.""",
            returnType: Map, () {
          return object!.tree();
        }),
        LEntry(
            name: "makeCurrent",
            descr: """Makes this star the current star.""", () {
          return object!.makeCurrent();
        }),
        LEntry(
            name: "checkout",
            descr:
                """Extracts the contents of this star, without needing to make it the current star.""",
            returnType: Stream,
            isAsync: true,
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
            isAsync: true, () async {
          return object!.checkForChanges();
        }),
        LEntry(
            name: "foward",
            descr:
                """Gets the star forward to this star X times, also known as descendants.
      
For general use, see [getChild](lua://SObject.getParent) or [getDescendants](lua://SObject.getAncestors)""",
            returnType: Star,
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
                """Gets the star backward to this star X times, also known as ancestors.

For general use, see [getParent](lua://SObject.getParent) or [getAncestors](lua://SObject.getAncestors).""",
            returnType: Star,
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
                """Gets the star above this star X times, also known as sibling stars.

For general use, see [getSiblingAbove](lua://SObject.getSiblingAbove).""",
            returnType: Star,
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
                """Gets the star below this star X times, also known as siblings.
                
For general use, see [getSiblingBelow](lua://SObject.getSiblingBelow).""",
            returnType: Star,
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
  
Will wrap around to the first child if X is greater than the number of children stars.""",
            returnType: Star,
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
            returnType: Star, () {
          return object!.recent();
        }),
        LEntry(
            name: "name",
            descr: """The name of the star.""",
            returnType: String,
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
            returnType: SArchive,
            returnNullable: true, () {
          return object!.archive;
        }),
        LEntry(
            name: "createdOn",
            descr: """The [DateTime](lua://DateTime) the star was created.""",
            returnType: DateTime, () {
          return object!.createdOn;
        }),
        LEntry(
            name: "constellation",
            descr: """The constellation of the star.""",
            returnType: Constellation, () {
          return object!.constellation;
        }),
        LEntry(
            name: "isRoot",
            descr: """True if the star is the root star.""",
            returnType: bool, () {
          return object!.isRoot;
        }),
        LEntry(
            name: "isCurrent",
            descr: """True if the star is the current star.""",
            returnType: bool, () {
          return object!.isCurrent;
        }),
        LEntry(
            name: "isSingleChild",
            descr: """True if the star is a single child.""",
            returnType: bool, () {
          return object!.isSingleChild;
        }),
        LEntry(
            name: "isLeaf",
            descr: """True if the star is a leaf.""",
            returnType: bool, () {
          return object!.isLeaf;
        }),
        LEntry(
            name: "isStem",
            descr: """True if the star is the stem of a branch.""",
            returnType: bool, () {
          return object!.isStem;
        })
      };
}

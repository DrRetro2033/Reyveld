part of 'star.dart';

final class StarInterface extends SInterface<Star> {
  @override
  String get className => "Star";

  @override
  get classDescription => """
This class represents a star in a constellation.
A star is a point in time that represents a snapshot of an folder.
""";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        tagEntry(StarFactory()),
      };

  @override
  get exports => {
        LEntry(
            name: "name",
            descr: "Gets or sets the name of the star.",
            args: const {
              LArg<String>(
                  name: "name",
                  descr: "The new name of the star.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: String,
            ([String? name]) => object!.name),
        LEntry(
            name: "constellation",
            descr: "Gets the constellation of the star.",
            returnType: Constellation,
            () => object!.constellation),
        LEntry(
            name: "makeCurrent",
            descr:
                """Sets the star as the current star. This method does not sync the tracked folder (i.e. it does not extract the contents of this star into the tracked folder), 
it just updates the current star in the constellation. If you want to sync the tracked folder, use [sync()](lua://Constellation.sync) to sync the tracked folder to this star.""",
            () {
          object!.makeCurrent();
        }),
        LEntry(
            name: "checkout",
            descr:
                "Extracts the contents of this star into the tracked folder, without updating the current star.",
            args: const {
              LArg<String>(
                  name: "path",
                  descr:
                      """The path to extract the contents of this star into. If not provided, the tracked folder will be used, just be sure not to overwrite any changes to the 
tracked folder by calling [checkForChanges()](lua://Constellation.checkForChanges) in the constellation.""",
                  kind: ArgKind.optionalPositional)
            },
            isAsync: true,
            ([String? path]) async =>
                await object!.checkout(path ?? object!.constellation.path)),
        LEntry(
            name: "archive",
            descr: "Gets the archive of the star.",
            returnType: SArchive,
            isAsync: true,
            () async => await object!.archive),
        LEntry(
            name: "trim",
            descr: "Trims this star and all of its descendants.",
            isAsync: true,
            () async => await object!.trim()),
        LEntry(
            name: "grow",
            descr: "Grows a new star from this star.",
            args: const {
              LArg<String>(
                name: "name",
                descr: "The name of the new star.",
              ),
              LArg<String>(
                  name: "branchName",
                  descr: "Makes this star the new stem for a new branch.",
                  kind: ArgKind.optionalNamed)
            },
            returnType: Star,
            isAsync: true,
            (String name, {String? branchName}) async =>
                await object!.grow(name, branchName: branchName)),
        LEntry(
            name: "isRoot",
            descr: "Checks if the star is the root star.",
            returnType: bool,
            () => object!.isRoot),
        LEntry(
            name: "isCurrent",
            descr: "Checks if the star is the current star",
            returnType: bool,
            () => object!.isCurrent),
        LEntry(
            name: "isSingleChild",
            descr:
                "Checks if the star is a single child. A single child is a star that has no siblings.",
            returnType: bool,
            () => object!.isSingleChild),
        LEntry(
            name: "isLeaf",
            descr:
                "Checks if the star is a leaf. A leaf is a star that has no children.",
            returnType: bool,
            () => object!.isLeaf),
        LEntry(
            name: "isStem",
            descr: "Checks if the star is a stem of a branch.",
            returnType: bool,
            () => object!.isStem),
        LEntry(
            name: "forward",
            descr:
                "Gets the star forward to this star X times, also known as children/descendants. When encountering a fork, the top most star will be chosen.",
            args: const {
              LArg<int>(
                  name: "x",
                  descr: "The number of stars to move forward.",
                  docDefaultValue: "1",
                  kind: ArgKind.optionalPositional)
            },
            returnType: Star, ([int x = 1]) async {
          Star star = object!;
          while (x > 0) {
            star = star.getChild<Star>() ?? star;
            x--;
          }
          return star;
        }),
        LEntry(
            name: "backward",
            descr:
                "Gets the star backward to this star X times, also known as parents/ancestors.",
            args: const {
              LArg<int>(
                  name: "x",
                  descr: "The number of stars to move backward.",
                  docDefaultValue: "1",
                  kind: ArgKind.optionalPositional)
            },
            returnType: Star, ([int x = 1]) {
          Star star = object!;
          while (x > 0) {
            star = star.getParent<Star>() ?? star;
            x--;
          }
          return star;
        }),
        LEntry(
            name: "above",
            descr:
                "Gets the star above this star X times, also known as siblings.",
            args: const {
              LArg<int>(
                  name: "x",
                  descr: "The number of stars to move up. Defaults to 1.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: Star, ([int x = 1]) {
          Star star = object!;
          while (x > 0) {
            star = star.getSiblingAbove<Star>() ?? star;
            x--;
          }
          return star;
        }),
        LEntry(
            name: "below",
            descr:
                "Gets the star below this star X times, also known as siblings.",
            args: const {
              LArg<int>(
                  name: "x",
                  descr: "The number of stars to move down. Defaults to 1.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: Star, ([int x = 1]) {
          Star star = object!;
          while (x > 0) {
            star = star.getSiblingBelow<Star>() ?? star;
            x--;
          }
          return star;
        }),
        LEntry(
            name: "next",
            descr: "Gets the Xth child of the star.",
            args: const {
              LArg<int>(name: "x", descr: "The Xth of the child to get.")
            },
            returnType: Star, (int x) {
          List<Star?> stars = object!.getChildren<Star>();
          Star star = stars[(x - 1) % stars.length] ?? object!;
          return star;
        }),
        LEntry(
            name: "recent",
            descr: "Gets the most recent decendant of the star.",
            returnType: Star, () {
          final stars = object!.getDescendants<Star>();
          stars.sort((a, b) => a!.createdOn.compareTo(b!.createdOn));
          return stars.last ?? object!;
        }),
        LEntry(
          name: "stem",
          descr:
              "Returns the stem of the branch this star is located in. To make this star a stem, use the anchor.",
          returnType: Star,
          () => object!.stem,
        ),
        LEntry(
          name: "branch",
          descr: "Sets and gets the branch name the star is located in.",
          args: const {
            LArg<String>(
                name: "name",
                descr: "The new name of the branch.",
                kind: ArgKind.optionalPositional)
          },
          returnType: Star,
          ([String? name]) {
            if (name != null) {
              /// A way of renaming a branch, without a separate function.
              object!.stem.makeStem(name);
            }
            return object!.branchName;
          },
        ),
        LEntry(
            name: "anchor",
            descr: "Makes this star the new stem for a new branch.",
            args: const {
              LArg<String>(
                name: "name",
                descr: "The name of the new branch.",
              )
            },
            returnType: Star, (String name) {
          object!.makeStem(name);
          return object!;
        }),
        LEntry(
          name: "tree",
          descr:
              "Returns a json representation of this star and its children as a tree.",
          returnType: Map,
          () => object!.tree(),
        ),
        LEntry(
            name: "unanchor",
            descr:
                """If this star is an stem, it will become a regular star, and the branch will no longer exist. 
Will never work on the root star, as it cannot be unanchored.""",
            returnType: Star, () {
          object!.unmakeStem();
          return object!;
        }),
        LEntry(
          name: "info",
          descr: "Returns a string of information about this star.",
          returnType: String,
          () => object!.info(),
        )
      };
}

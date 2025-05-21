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
              "name": LArg<String>(
                  descr: "The new name of the star.", required: false)
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
            descr: "Sets the star as the current star.",
            args: const {
              "updateFolder": LArg<bool>(
                  descr:
                      "If true, the folder will be updated to the current star.",
                  required: false)
            },
            isAsync: true, ([bool updateFolder = true]) async {
          object!.makeCurrent();
          if (updateFolder) {
            await object!.constellation.updateToCurrent();
          }
        }),
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
              "name": LArg<String>(
                descr: "The name of the new star.",
              )
            },
            returnType: Star,
            isAsync: true,
            (String name) async => await object!.grow(name)),
        LEntry(
            name: "isRoot",
            descr: "Checks if the star is the root star.",
            returnType: bool,
            () => object!.isRoot),
        LEntry(
            name: "isCurrent",
            descr: "Checks if the star is the current star.",
            returnType: bool,
            () => object!.isCurrent),
        LEntry(
            name: "isSingleChild",
            descr: "Checks if the star is a single child.",
            returnType: bool,
            () => object!.isSingleChild),
        LEntry(
            name: "forward",
            descr: "Gets the star forward to this star X times.",
            args: const {
              "x": LArg<int>(
                  descr: "The number of stars to move forward. Defaults to 1.",
                  required: false)
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
            descr: "Gets the star backward to this star X times.",
            args: const {
              "x": LArg<int>(
                  descr: "The number of stars to move backward. Defaults to 1.",
                  required: false)
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
            descr: "Gets the star above this star X times.",
            args: const {
              "x": LArg<int>(
                  descr: "The number of stars to move up. Defaults to 1.",
                  required: false)
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
            descr: "Gets the star below this star X times.",
            args: const {
              "x": LArg<int>(
                  descr: "The number of stars to move down. Defaults to 1.",
                  required: false)
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
            args: const {"x": LArg<int>(descr: "The Xth of the child to get.")},
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
        })
      };
}

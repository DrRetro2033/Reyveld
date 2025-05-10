part of 'star.dart';

class StarInterface extends SInterface<Star> {
  @override
  String get className => "Star";

  @override
  get description => """
This class represents a star in a constellation.
A star is a point in time that represents a snapshot of an folder.
""";

  @override
  get parent => SObjectInterface();

  @override
  get exports => {
        "name": (
          "Gets or sets the name of the star.",
          {
            "name": (
              "The new name of the star.",
              type: String,
              isRequired: false
            )
          },
          String,
          ([String? name]) => object!.name
        ),
        "constellation": (
          "Gets the constellation of the star.",
          {},
          Constellation,
          () => object!.constellation
        ),
        "makeCurrent": (
          "Sets the star as the current star.",
          {
            "updateFolder": (
              "If true, the folder will be updated to the current star.",
              type: bool,
              isRequired: false
            )
          },
          null,
          ([bool updateFolder = true]) async {
            object!.makeCurrent();
            if (updateFolder) {
              await object!.constellation.updateToCurrent();
            }
          }
        ),
        "getArchive": (
          "Gets the archive of the star.",
          {},
          SArchive,
          () async => await object!.archive
        ),
        "trim": (
          "Trims this star and all of its descendants.",
          {},
          null,
          () async => await object!.trim()
        ),
        "grow": (
          "Grows a new star from this star.",
          {
            "name": (
              "The name of the new star.",
              type: String,
              isRequired: true
            )
          },
          Star,
          (String name) async => await object!.grow(name)
        ),
        "isRoot": (
          "Checks if the star is the root star.",
          {},
          bool,
          () => object!.isRoot
        ),
        "isCurrent": (
          "Checks if the star is the current star.",
          {},
          bool,
          () => object!.isCurrent
        ),
        "isSingleChild": (
          "Checks if the star is a single child.",
          {},
          bool,
          () => object!.isSingleChild
        ),
        "forward": (
          "Gets the star forward to this star X times.",
          {
            "x": (
              "The number of stars to move forward. Defaults to 1.",
              type: int,
              isRequired: false
            )
          },
          Star,
          ([int x = 1]) async {
            Star star = object!;
            while (x > 0) {
              star = star.getChild<Star>() ?? star;
              x--;
            }
            return star;
          }
        ),
        "backward": (
          "Gets the star backward to this star X times.",
          {
            "x": (
              "The number of stars to move backward. Defaults to 1.",
              type: int,
              isRequired: false
            )
          },
          Star,
          ([int x = 1]) async {
            Star star = object!;
            while (x > 0) {
              star = star.getParent<Star>() ?? star;
              x--;
            }
            return star;
          }
        ),
        "above": (
          "Gets the star above this star X times.",
          {
            "x": (
              "The number of stars to move up. Defaults to 1.",
              type: int,
              isRequired: false
            )
          },
          Star,
          ([int x = 1]) async {
            Star star = object!;
            while (x > 0) {
              star = star.getSiblingAbove<Star>() ?? star;
              x--;
            }
            return star;
          }
        ),
        "below": (
          "Gets the star below this star X times.",
          {
            "x": (
              "The number of stars to move down. Defaults to 1.",
              type: int,
              isRequired: false
            )
          },
          Star,
          ([int x = 1]) async {
            Star star = object!;
            while (x > 0) {
              star = star.getSiblingBelow<Star>() ?? star;
              x--;
            }
            return star;
          }
        ),
        "next": (
          "Gets the Xth child of the star.",
          {"x": ("The Xth of the child to get.", type: int, isRequired: true)},
          Star,
          (int x) async {
            List<Star?> stars = object!.getChildren<Star>();
            Star star = stars[(x - 1) % stars.length] ?? object!;
            return star;
          }
        ),
        "recent": (
          "Gets the most recent decendant of the star.",
          {},
          Star,
          () {
            final stars = object!.getDescendants<Star>();
            stars.sort((a, b) => a!.createdOn.compareTo(b!.createdOn));
            return stars.last ?? object!;
          }
        )
      };
}

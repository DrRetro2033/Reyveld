part of 'constellation.dart';

class ConstellationInterface extends SInterface<Constellation> {
  @override
  get className => "Constellation";

  @override
  get classDescription => """
A collection of Stars, with a root star, and a current star.
""";

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        "tag": (
          "Get the xml tag of the SObject type.",
          {},
          String,
          false,
          () => ConstellationFactory().tag
        ),
        "new": (
          "Creates a new constellation.",
          const {
            "name": (
              "The name of the constellation.",
              type: String,
              cast: typeCheck<String>,
              isRequired: true
            ),
            "path": (
              "The path of the constellation.",
              type: String,
              cast: typeCheck<String>,
              isRequired: true
            )
          },
          Constellation,
          false,
          (String name, String path) async =>
              await ConstellationCreator(name, path).create()
        )
      };

  @override
  get exports => {
        "name": (
          "Gets the name of the constellation.",
          {},
          String,
          false,
          () => object?.name
        ),
        "path": (
          "Gets the path of the constellation.",
          {},
          String,
          false,
          () => object?.path
        ),
        "current": (
          "Gets the current star of the constellation.",
          {},
          Star,
          false,
          () => object?.getCurrentStar()
        ),
        "start": (
          "Starts the constellation by creating the root star. Call after adding the constellation to the kit.",
          {},
          Star,
          true,
          () async => await object?.createRootStar()
        ),
        "root": (
          "Gets the root star of the constellation.",
          {},
          Star,
          false,
          () => object?.root
        ),
        "unsaved": (
          "Gets an archive that contains all of the unsaved changes in the constellation.",
          {},
          SArchive,
          true,
          () async => await object?.getUnsavedChanges()
        )
      };
}

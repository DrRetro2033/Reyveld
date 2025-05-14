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
          () => SFileFactory().tag
        ),
        "new": (
          "Creates a new constellation.",
          {
            "name": (
              "The name of the constellation.",
              type: String,
              cast: (value) => value as String,
              isRequired: true
            ),
            "path": (
              "The path of the constellation.",
              type: String,
              cast: (value) => value as String,
              isRequired: true
            )
          },
          Constellation,
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
          () => object?.name
        ),
        "path": (
          "Gets the path of the constellation.",
          {},
          String,
          () => object?.path
        ),
        "current": (
          "Gets the current star of the constellation.",
          {},
          Star,
          () => object?.getCurrentStar()
        ),
        "start": (
          "Starts the constellation by creating the root star. Call after adding the constellation to the kit.",
          {},
          Star,
          () async => await object?.createRootStar()
        ),
        "root": (
          "Gets the root star of the constellation.",
          {},
          Star,
          () => object?.root
        ),
        "unsaved": (
          "Gets an archive that contains all of the unsaved changes in the constellation.",
          {},
          SArchive,
          () async => await object?.getUnsavedChanges()
        )
      };
}

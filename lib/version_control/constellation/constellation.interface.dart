part of 'constellation.dart';

final class ConstellationInterface extends SInterface<Constellation> {
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
        tagEntry(ConstellationFactory()),
        LEntry(
            name: "create",
            descr: "Creates a new constellation.",
            args: const {
              "name": LArg<String>(
                descr: "The name of the constellation.",
              ),
              "path": LArg<String>(
                descr: "The path of the constellation.",
              )
            },
            returnType: Constellation,
            (String name, String path) async =>
                await ConstellationCreator(name, path).create())
      };

  @override
  get exports => {
        LEntry(
            name: "name",
            descr: "Gets the name of the constellation.",
            returnType: String,
            () => object?.name),
        LEntry(
            name: "path",
            descr: "Gets the path of the constellation.",
            returnType: String,
            () => object?.path),
        LEntry(
            name: "current",
            descr: "Gets the current star of the constellation.",
            returnType: Star,
            () => object?.getCurrentStar()),
        LEntry(
            name: "start",
            descr:
                "Starts the constellation by creating the root star. Call after adding the constellation to the kit.",
            returnType: Star,
            isAsync: true,
            () async => await object?.createRootStar()),
        LEntry(
            name: "root",
            descr: "Gets the root star of the constellation.",
            returnType: Star,
            isAsync: false,
            () => object?.root),
        LEntry(
            name: "unsaved",
            descr:
                "Gets an archive that contains all of the unsaved changes in the constellation.",
            returnType: SArchive,
            isAsync: true,
            () async => await object?.getUnsavedChanges())
      };
}

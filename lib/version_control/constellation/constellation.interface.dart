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
            name: "new",
            descr: "Creates a new constellation.",
            args: const {
              LArg<String>(
                name: "name",
                descr: "The name of the constellation.",
              ),
              LArg<String>(
                name: "path",
                descr: "The path of the constellation.",
              )
            },
            returnType: Constellation, (String name, String path) async {
          return await ConstellationCreator(name, path).create();
        })
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
            args: const {
              LArg<bool>(
                name: "throwIfExists",
                descr:
                    "Throws an exception if the constellation already has a root star.",
                kind: ArgKind.optionalPositional,
                docDefaultValue: "true",
              )
            },
            returnType: Star,
            isAsync: true,
            ([bool throwIfExists = true]) async =>
                await object?.createRootStar(throwIfExists: throwIfExists)),
        LEntry(
          name: "hasRoot",
          descr: "Returns true if the constellation has a root star.",
          returnType: bool,
          () => object?.hasRoot,
        ),
        LEntry(
            name: "root",
            descr: "Gets the root star of the constellation.",
            returnType: Star,
            isAsync: false,
            () => object?.root),
        LEntry(
            name: "globs",
            descr:
                "Gets and sets the globs of the constellation. Used to specify which files to track, and which files to ignore.",
            args: const {
              LArg<Globs>(
                  name: "filelist",
                  descr: "The globs to set.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: Globs, ([Globs? filelist]) {
          if (filelist != null) {
            object?.globs = filelist;
          }
          return object?.globs;
        }),
        LEntry(
            name: "unsaved",
            descr:
                "Gets an archive that contains all of the unsaved changes in the constellation.",
            returnType: SArchive,
            isAsync: true,
            () async => await object?.getUnsavedChanges()),
        LEntry(
          name: "getStem",
          descr: "Get the start of a named branch.",
          args: const {
            LArg<String>(name: "branch", descr: "The name of the branch.")
          },
          returnType: Star,
          (String branch) => object?.getStartOfBranch(branch),
        ),
        LEntry(
            name: "getAllBranches",
            descr: "Get all of the branches.",
            returnType: List,
            () => object?.getAllBranches().toList()),
        LEntry(
            name: "sync",
            descr: "Syncs the tracked folder to the current star.",
            returnType: Stream,
            isAsync: true,
            () async => await object!.sync()),
        LEntry(
            name: "checkForChanges",
            descr:
                "Checks for changes in the tracked folder against the current star.",
            returnType: bool,
            isAsync: true,
            () async => await object!.checkForChanges()),
        LEntry(
            name: "starByHash",
            descr: "Get a star by hash.",
            args: const {
              LArg<String>(name: "hash", descr: "The hash of the star.")
            },
            returnType: Star, (String hash) {
          return object?.getStarByHash(hash);
        })
      };
}

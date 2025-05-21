part of 'arceus.dart';

class ArceusInterface extends SInterface<Arceus> {
  @override
  get className => "Arceus";

  @override
  get staticDescription => """
Contains global functions for Arceus, for example, settings, paths, etc.
""";

  @override
  get statics => {
        LEntry(
            name: "installLib",
            descr: "Install a new library into Arceus.",
            args: {
              "path": LArg<String>(
                descr: "The path to the library.",
              )
            },
            isAsync: true, (String path) async {
          final skit = SKit(path);
          if (await skit.isType(SKitType.library)) {
            await Arceus.registerLibrary(path);
          }
        }),
        LEntry(
            name: "uninstallLib",
            descr: "Uninstall a library from Arceus.",
            args: {
              "name": LArg<String>(
                descr: "The name of the library.",
              )
            },
            isAsync: true, (String name) async {
          await Arceus.unregisterLibrary(name);
        })
      };
}

part of 'arceus.dart';

class ArceusInterface extends SInterface {
  @override
  get className => "Arceus";

  @override
  get staticDescription => """
Contains global functions for Arceus, for example, settings, paths, etc.
""";

  @override
  get statics => {
        "installLib": (
          "Install a new library into Arceus.",
          {
            "path": (
              "The path to the library.",
              isRequired: true,
              cast: (value) => value as String,
              type: String
            )
          },
          null,
          true,
          (String path) async {
            final skit = SKit(path);
            if (await skit.isType(SKitType.library)) {
              await Arceus.registerLibrary(path);
            }
          }
        ),
        "uninstallLib": (
          "Uninstall a library from Arceus.",
          {
            "name": (
              "The name of the library.",
              isRequired: true,
              cast: (value) => value as String,
              type: String
            )
          },
          null,
          true,
          (String name) async {
            await Arceus.unregisterLibrary(name);
          }
        )
      };
}

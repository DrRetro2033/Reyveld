part of 'library.dart';

class SLibraryInterface extends SInterface<SLibrary> {
  @override
  get className => "SLibrary";

  @override
  get classDescription => """
This interface represents an Arceus library.
A library contains Lua code that can be used to reuse code between projects easily.
For example, you can create a library that contains code to read and write Pokemon from a file, or
read and write to an image file, or more.
  """;

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        "new": (
          "Create a new library.",
          const {
            "name": (
              "The name of the library.",
              isRequired: true,
              type: String,
              cast: typeCheck<String>
            ),
            "description": (
              "The description of the library.",
              isRequired: true,
              type: String,
              cast: typeCheck<String>
            ),
            "authors": (
              "A list of authors.",
              isRequired: true,
              type: List,
              cast: typeCheck<List<SAuthor>>
            )
          },
          SLibrary,
          true,
          (String name, String description, List<SAuthor> authors) async =>
              await SLibraryCreator(name,
                      description: description, authors: authors)
                  .create()
        )
      };

  @override
  get exports => {
        "package": (
          "Package a directory into the library.",
          const {
            "path": (
              "The path to the directory.",
              isRequired: true,
              type: String,
              cast: typeCheck<String>
            ),
          },
          SLibrary,
          true,
          (String path) async {
            await object!.package(path);
          }
        ),
      };
}

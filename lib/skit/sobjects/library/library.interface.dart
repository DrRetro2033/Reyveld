part of 'library.dart';

class SLibraryInterface extends SInterface<SLibrary> {
  @override
  get className => "SLibrary";

  @override
  get description => """
This interface represents an Arceus library.
A library contains a name, an archive reference, a description, and a list of authors.

A library is a collection of SKits that contain Lua code that can be used to reuse code between projects easily.
For example, you can create a library that contains code to read and write Pokemon from a file, or
read and write to an image file, or more.
  """;

  @override
  get statics => {
        "new": (
          "Create a new library.",
          {
            "name": (
              "The name of the library.",
              isRequired: true,
              type: String
            ),
            "description": (
              "The description of the library.",
              isRequired: true,
              type: String
            ),
            "authors": ("A list of authors.", isRequired: true, type: List)
          },
          SLibrary,
          (String name, String description, List<SAuthor> authors) async =>
              await SLibraryCreator(name,
                      description: description, authors: authors)
                  .create()
        )
      };

  @override
  get exports => {
        "package": (
          "Package a directory as the library.",
          {
            "path": (
              "The path to the directory.",
              isRequired: true,
              type: String
            ),
          },
          SLibrary,
          (String path) async {
            await object!.package(path);
          }
        )
      };
}

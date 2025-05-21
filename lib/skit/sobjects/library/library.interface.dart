part of 'library.dart';

final class SLibraryInterface extends SInterface<SLibrary> {
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
        tagEntry(SLibraryFactory()),
        LEntry(
            name: "create",
            descr: "Create a new library.",
            args: const {
              "name": LArg<String>(
                descr: "The name of the library.",
              ),
              "description": LArg<String>(
                descr: "The description of the library.",
              ),
              "authors": LArg<List>(
                descr: "A list of authors.",
              )
            },
            returnType: SLibrary,
            isAsync: true,
            (String name, String description, List<SAuthor> authors) async =>
                await SLibraryCreator(name,
                        description: description, authors: authors)
                    .create())
      };

  @override
  get exports => {
        LEntry(
            name: "package",
            descr: "Package a directory into the library.",
            args: const {
              "path": LArg<String>(
                descr: "The path to the directory.",
              ),
            },
            returnType: SLibrary,
            isAsync: true, (String path) async {
          await object!.package(path);
        }),
      };
}

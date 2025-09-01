part of 'skit.dart';

/// The interface for the [SKit] class.
class SKitInterface extends SInterface<SKit> {
  @override
  get className => "SKit";

  @override
  get classDescription => """
SKits are the bread and butter of Arceus. They store a SHeader and any number of SRoots in a single file.
""";

  @override
  get statics => {
        LEntry(
            name: "open",
            descr: "Opens an SKit file.",
            securityCheck: (cert, args) =>
                cert
                    .getPolicy<SPolicySKit>()
                    ?.readAllowed(args.positional[0]) ??
                false,
            args: const {
              LArg<String>(
                name: "path",
                descr: "The path to the SKit file.",
              ),
              LArg<String>(
                  name: "key",
                  descr: "The encryption key.",
                  kind: ArgKind.optionalNamed),
            },
            returnType: SKit,
            isAsync: true,
            (String path, {String key = ""}) async =>
                await SKit.open(path, encryptKey: key)),
        LEntry(
            name: "exists",
            descr: "Checks if an SKit exists.",
            args: const {
              LArg<String>(
                name: "path",
                descr: "The path to the SKit file.",
              )
            },
            returnType: bool,
            isAsync: true, (String path) async {
          return await SKit(path).exists();
        }),
        LEntry(
            name: "create",
            descr: "Creates a new SKit file.",
            args: const {
              LArg<String>(
                name: "path",
                descr: "The path to the SKit file.",
              ),
              LArg<bool>(
                  name: "overwrite",
                  descr: "Whether to overwrite the file if it already exists.",
                  kind: ArgKind.optionalNamed),
              LArg<int>(
                  name: "type",
                  descr: "The type of the SKit.",
                  kind: ArgKind.optionalNamed),
              LArg<String>(
                  name: "key",
                  descr: "The encryption key.",
                  kind: ArgKind.optionalNamed),
            },
            returnType: SKit,
            isAsync: true, (String path,
                {bool overwrite = false, int? type, String key = ""}) async {
          final skit = SKit(path, encryptKey: key);
          await skit.create(
              overwrite: overwrite,
              type:
                  type != null ? SKitType.values[type] : SKitType.unspecified);
          return skit;
        }),
      };

  @override
  get exports => {
        LEntry(
            name: "path",
            descr: "Returns the path of the SKit file.",
            returnType: String,
            () => object!.path),
        LEntry(
            name: "isType",
            descr: "Returns whether the SKit is of the specified type.",
            args: const {
              LArg<int>(name: "type", descr: "The type to check for.")
            },
            returnType: bool,
            isAsync: true, (int type) async {
          return await object!.isType(SKitType.values[type]);
        }),
        LEntry(
            name: "type",
            descr: "Returns the type of the SKit.",
            returnType: int,
            isAsync: true,
            () async => (await object!.type).index),
        LEntry(
            name: "header",
            descr: "Returns the SHeader of the SKit.",
            returnType: SHeader,
            isAsync: true,
            () => object!.getHeader()),
        LEntry(
            name: "createdOn",
            descr: "Returns the creation date of the SKit.",
            returnType: String,
            isAsync: true, () async {
          final header = await object!.getHeader();
          return header!.createdOn.toIso8601String();
        }),
        LEntry(
            name: "lastModified",
            descr: "Returns the last modified date of the SKit.",
            returnType: String,
            isAsync: true, () async {
          final header = await object!.getHeader();
          return header!.lastModified.toIso8601String();
        }),
        LEntry(
            name: "key",
            descr: "Sets and Gets the encryption key of the SKit.",
            args: const {
              LArg<String>(
                  name: "key",
                  descr: "The encryption key.",
                  kind: ArgKind.optionalPositional),
            },
            returnType: String, ([String? key]) async {
          if (key != null) {
            object!.key = key;
          }
          return object!.key;
        }),
        LEntry(
            name: "author",
            descr: "Returns the author of the kit.",
            isAsync: true,
            returnType: SAuthor,
            () async => await object!.author),
        LEntry(
            name: "verify",
            descr: "Verifies the kit file to make sure it is signed properly.",
            isAsync: true,
            returnType: bool,
            () => object!.verify()),
        LEntry(
            name: "usedHashes",
            descr: "Returns the hashes used by the roots in the SKit.",
            args: const {
              LArg<String>(
                  name: "tag",
                  descr: "The tag to filter by.",
                  kind: ArgKind.optionalNamed),
            },
            returnType: List,
            isAsync: true, ({String? tag}) async {
          return (await object!.usedRootHashes()).toList();
        }),
        LEntry(
            name: "save",
            descr: "Saves changes to the SKit.",
            isAsync: true,
            () => object!.save()),
        LEntry(
            name: "discard",
            descr: "Discards changes to the SKit.",
            () => object!.discardChanges()),
        LEntry(
            name: "exportAs",
            descr: "Exports the SKit as an uncompressed, decrypted xml file.",
            args: const {
              LArg<String>(name: "path", descr: "The path to export to.")
            },
            isAsync: true,
            (String path) async => await object!.exportToXMLFile(path))
      };
}

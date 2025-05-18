part of 'skit.dart';

class SKitInterface extends SInterface<SKit> {
  @override
  get className => "SKit";

  @override
  get classDescription => """
SKits are the bread and butter of Arceus. They store a SHeader and any number of SRoots in a single file.
""";

  @override
  get statics => {
        "open": (
          "Opens an SKit file.",
          {
            "path": const (
              "The path to the SKit file.",
              type: String,
              cast: typeCheck<String>,
              isRequired: true
            ),
            "overrides": const (
              "Some more options.",
              type: Map,
              cast: typeCheck<Map>,
              isRequired: false
            ),
          },
          SKit,
          true,
          (String path, [Map overrides = const {}]) async {
            String? encryptKey =
                overrides.containsKey("key") ? overrides["key"] : null;
            return await SKit.open(path, encryptKey: encryptKey ?? "");
          }
        ),
        "exists": (
          "Checks if an SKit exists.",
          {
            "path": const (
              "The path to the SKit file.",
              type: String,
              cast: typeCheck<String>,
              isRequired: true
            )
          },
          bool,
          true,
          (String path) async {
            return await SKit(path).exists();
          }
        ),
        "create": (
          "Creates a new SKit file.",
          const {
            "path": (
              "The path to the SKit file.",
              type: String,
              cast: typeCheck<String>,
              isRequired: true
            ),
            "overrides": (
              "Some more options.",
              type: Map,
              cast: typeCheck<Map>,
              isRequired: false
            ),
          },
          SKit,
          true,
          (String path, [Map overrides = const {}]) async {
            bool? overwrite = overrides.containsKey("override")
                ? overrides["override"]
                : null;
            SKitType? type = overrides.containsKey("type")
                ? SKitType.values
                    .firstWhere((e) => e.index == overrides["type"])
                : null;
            String? encryptKey =
                overrides.containsKey("key") ? overrides["key"] : null;
            final skit = SKit(path, encryptKey: encryptKey ?? "");
            await skit.create(
                overwrite: overwrite ?? false,
                type: type ?? SKitType.unspecified);
            return skit;
          }
        ),
      };

  @override
  get exports => {
        "path": (
          "Returns the path of the SKit file.",
          {},
          String,
          false,
          () => object!.path
        ),
        "isType": (
          "Returns whether the SKit is of the specified type.",
          const {
            "type": (
              "The type to check for.",
              type: int,
              cast: typeCheck<int>,
              isRequired: true
            )
          },
          bool,
          true,
          (int type) async {
            return await object!.isType(SKitType.values[type]);
          }
        ),
        "header": (
          "Returns the SHeader of the SKit.",
          {},
          SHeader,
          true,
          () => object!.getHeader()
        ),
        "createdOn": (
          "Returns the creation date of the SKit.",
          {},
          String,
          true,
          () async {
            final header = await object!.getHeader();
            return header!.createdOn.toIso8601String();
          }
        ),
        "modifiedOn": (
          "Returns the last modified date of the SKit.",
          {},
          String,
          true,
          () async {
            final header = await object!.getHeader();
            return header!.lastModified.toIso8601String();
          }
        ),
        "key": (
          "Sets and Gets the encryption key of the SKit.",
          const {
            "key": (
              "The encryption key.",
              type: String,
              cast: typeCheck<String>,
              isRequired: false
            ),
          },
          String,
          false,
          ([String? key]) async {
            if (key != null) {
              object!.key = key;
            }
            return object!.key;
          }
        ),
        "save": (
          "Saves changes to the SKit.",
          {},
          null,
          true,
          () => object!.save()
        ),
        "discard": (
          "Discards changes to the SKit.",
          {},
          null,
          false,
          () => object!.discardChanges()
        ),
        "exportAs": (
          "Exports the SKit as an uncompressed, decrypted xml file.",
          const {
            "path": (
              "The path to export to.",
              type: String,
              cast: typeCheck<String>,
              isRequired: true
            )
          },
          null,
          true,
          (String path) async => await object!.exportToXMLFile(path)
        )
      };
}

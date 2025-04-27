part of 'skit.dart';

class SKitInterface extends SInterface<SKit> {
  @override
  get className => "SKit";

  @override
  get description => """""";

  @override
  get extras => """
---@enum SKitType
SKitType = {
  ${SKitType.values.map((e) => "${e.name} = ${e.index},").join("\n  ")}
}
""";

  @override
  get exports => {
        "path": (
          "Returns the path of the SKit file.",
          {},
          String,
          (_) => object!.path
        ),
        "isType": (
          "Returns whether the SKit is of the specified type.",
          {"type": ("The type to check for.", int, true)},
          bool,
          (state) async {
            return await object!
                .isType(SKitType.values[await state.getFromTop<int>()]);
          }
        ),
        "createdOn": (
          "Returns the creation date of the SKit.",
          {},
          String,
          (state) async {
            final header = await object!.getHeader();
            return header!.createdOn.toIso8601String();
          }
        ),
        "modifiedOn": (
          "Returns the last modified date of the SKit.",
          {},
          String,
          (state) async {
            final header = await object!.getHeader();
            return header!.lastModified.toIso8601String();
          }
        ),
        "getConstellation": (
          "Returns the constellation of the SKit.",
          {},
          Constellation,
          (_) async => await object!
              .getHeader()
              .then((e) => e!.getChild<Constellation>())
        ),
        "newConstellation": (
          "Creates a new constellation in the SKit.",
          {
            "name": ("The name of the constellation.", String, true),
            "path": ("The path of the constellation.", String, true),
          },
          Constellation,
          (state) async {
            final path = await state.getFromTop<String>();
            final name = await state.getFromTop<String>();
            final constellation =
                await ConstellationCreator(name, path).create(object!);
            await constellation.createRootStar();
            object!.getHeader().then((e) => e!.addChild(constellation));
            return constellation;
          }
        ),
        "save": (
          "Saves changes to the SKit.",
          {},
          null,
          (state) async => await object!.save()
        ),
        "discard": (
          "Discards changes to the SKit.",
          {},
          null,
          (_) => object!.discardChanges()
        ),
      };

  @override
  get statics => {
        "open": (
          "Opens an SKit file.",
          {"path": ("The path to the SKit file.", String, true)},
          SKit,
          (state) async {
            final path = await state.getFromTop<String>();
            return await SKit.open(path);
          }
        ),
        "exists": (
          "Checks if an SKit exists.",
          {"path": ("The path to the SKit file.", String, true)},
          bool,
          (state) async {
            final path = await state.getFromTop<String>();
            return await SKit(path).exists();
          }
        ),
        "create": (
          "Creates a new SKit file.",
          {
            "path": ("The path to the SKit file.", String, true),
            "overrides": ("Some more options.", Map, false),
          },
          SKit,
          (lua) async {
            bool? overwrite;
            SKitType? type;
            if (lua.state.getTop() == 2 && lua.state.isTable(2)) {
              final table = await lua.getFromTop<Map<String, dynamic>>();
              overwrite =
                  table.containsKey("override") ? table["override"] : null;
              type = table.containsKey("type")
                  ? SKitType.values.firstWhere((e) => e.index == table["type"])
                  : null;
            }
            final path = await lua.getFromTop<String>();

            final skit = SKit(path);
            await skit.create(
                overwrite: overwrite ?? false,
                type: type ?? SKitType.unspecified);
            return skit;
          }
        ),
      };
}

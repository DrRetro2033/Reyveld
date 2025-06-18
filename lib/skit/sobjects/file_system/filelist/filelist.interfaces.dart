part of 'filelist.dart';

class GlobsInterface extends SInterface<Globs> {
  GlobsInterface();

  @override
  get className => 'Globs';

  @override
  get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
            name: "whitelist",
            descr: "The list of files to include.",
            returnType: Whitelist, () async {
          return await WhitelistCreator([]).create();
        }),
        LEntry(
            name: "blacklist",
            descr: "The list of files to exclude.",
            returnType: Blacklist, (List<String> globs) async {
          return await BlacklistCreator([]).create();
        }),
      };
}

class WhitelistInterface extends SInterface<Whitelist> {
  @override
  get parent => GlobsInterface();

  WhitelistInterface();

  @override
  get className => 'Whitelist';

  @override
  get exports => {
        LEntry(
          name: "add",
          descr: "Adds a glob to the whitelist.",
          args: {"glob": LArg<String>(descr: "The glob to add.")},
          returnType: Whitelist,
          (String glob) async {
            return object!..add(glob);
          },
        ),
        LEntry(
          name: "remove",
          descr: "Removes a glob from the whitelist.",
          args: {"glob": LArg<String>(descr: "The glob to remove.")},
          returnType: Whitelist,
          (String glob) async {
            return object!..remove(glob);
          },
        ),
      };
}

class BlacklistInterface extends SInterface<Blacklist> {
  @override
  get parent => GlobsInterface();

  BlacklistInterface();

  @override
  get className => 'blacklist';

  @override
  get exports => {
        LEntry(
          name: "add",
          descr: "Adds a glob to the blacklist.",
          args: {"glob": LArg<String>(descr: "The glob to add.")},
          returnType: Blacklist,
          (String glob) async {
            return object!..add(glob);
          },
        ),
        LEntry(
          name: "remove",
          descr: "Removes a glob from the blacklist.",
          args: {"glob": LArg<String>(descr: "The glob to remove.")},
          returnType: Blacklist,
          (String glob) async {
            return object!..remove(glob);
          },
        ),
      };
}

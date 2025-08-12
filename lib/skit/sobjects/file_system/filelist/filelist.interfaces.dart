part of 'filelist.dart';

class GlobsInterface<T extends Globs> extends SInterface<Globs> {
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

  @override
  get exports => {
        LEntry(
          name: "add",
          descr: "Adds a glob to the whitelist.",
          args: const {"glob": LArg<String>(descr: "The glob to add.")},
          returnType: T,
          (String glob) async {
            return object!..add(glob);
          },
        ),
        LEntry(
            name: "addAll",
            descr: "Adds multiple globs to the whitelist.",
            args: const {"globs": LArg<List>(descr: "The globs to add.")},
            returnType: T,
            (List globs) async =>
                object!..addAll(globs.whereType<String>().toList())),
        LEntry(
          name: "remove",
          descr: "Removes a glob from the whitelist.",
          args: const {"glob": LArg<String>(descr: "The glob to remove.")},
          returnType: T,
          (String glob) async {
            return object!..remove(glob);
          },
        ),
      };
}

class WhitelistInterface extends SInterface<Whitelist> {
  @override
  get parent => GlobsInterface<Whitelist>();

  WhitelistInterface();

  @override
  get className => 'Whitelist';
}

class BlacklistInterface extends SInterface<Blacklist> {
  @override
  get parent => GlobsInterface<Blacklist>();

  BlacklistInterface();

  @override
  get className => 'Blacklist';
}

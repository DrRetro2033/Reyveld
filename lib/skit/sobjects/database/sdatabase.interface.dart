part of 'sdatabase.dart';

class SDatabaseInterface extends SInterface<SDatabase> {
  @override
  get className => "SDatabase";

  @override
  String get classDescription =>
      """A database inside of a [SKit](lua://SKit) file.""";

  @override
  get statics => {
        LEntry(
            name: "new",
            descr: """Create a new [SDatabase] object.""",
            returnType: SDatabase,
            docReturnTypeOverride: "SDatabase",
            isAsync: true,
            () async => await SDatabaseCreator().create()),
      };

  @override
  get exports => {
        LEntry(
            name: "get",
            descr: """Get entries from the database.""",
            returnType: List,
            docReturnTypeOverride: "SCustom[]",
            isAsync: true,
            args: const {
              LArg<LuaFuncRef>(
                  name: "func",
                  descr: "The method to call for each entry.",
                  docTypeOverride: "fun(entry: SCustom):boolean"),
            }, (LuaFuncRef func) async {
          final result = <SCustom>[];
          for (final entry in object!.getChildren<SCustom>()) {
            if (await func.call([entry])) {
              result.add(entry!);
            }
          }
          return result;
        }),
      };
}

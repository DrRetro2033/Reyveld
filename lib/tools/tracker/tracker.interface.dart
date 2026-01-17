part of 'tracker.dart';

class ChangeTrackerInterface extends SInterface<ChangeTracker> {
  @override
  get className => "ChangeTracker";

  @override
  get classDescription =>
      "Tracks any changes that have occurred, like a file changing or something else.";

  @override
  get statics => {
        LEntry(
            name: "new",
            descr: "Creates a new ChangeTracker instance.",
            returnType: ChangeTracker,
            args: const {
              LArg<LuaFuncRef>(
                name: "checker",
                descr: "The check to run to see if there are any changes.",
                docTypeOverride: "func(): boolean",
              ),
              LArg<LuaFuncRef>(
                  name: "onChanged",
                  descr: "The function to call when there are changes.",
                  docTypeOverride: "func(e: any)")
            },
            (LuaFuncRef checker, LuaFuncRef onChanged) =>
                ChangeTracker(() async => await checker.call([]))
                  ..onChange.listen((e) async => await onChanged.call([e])))
      };

  @override
  get exports => {
        LEntry(
            name: "start",
            descr: "Starts the change tracker.",
            () => object!.start()),
      };
}

part of 'tracker.dart';

class ChangeTrackerInterface extends SInterface<ChangeTracker> {
  @override
  get className => "ChangeTracker";

  @override
  get classDescription => "Tracks changes in a document.";

  @override
  get statics => {
        LEntry(
            name: "new",
            descr: "Creates a new ChangeTracker instance.",
            returnType: ChangeTracker,
            args: const {
              LArg<LuaFuncRef>(
                name: "checker",
              )
            },
            (LuaFuncRef checker) =>
                ChangeTracker(() async => await checker.call([])))
      };
}

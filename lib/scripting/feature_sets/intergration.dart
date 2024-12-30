import '../addon.dart';
import '../squirrel.dart';

class IntergrationAddonContext extends AddonContext {
  IntergrationAddonContext(super.addon);

  @override
  List<SquirrelFunction> get functions => [];

  void launch(String endpoint) {
    final vm = startVM();
    Squirrel.call(vm, "launch", args: [endpoint]);
    Squirrel.dispose(vm);
  }
}

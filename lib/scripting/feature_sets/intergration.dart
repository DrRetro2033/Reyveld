import 'package:yaml/yaml.dart';

import 'package:arceus/scripting/addon.dart';
import 'package:arceus/scripting/squirrel.dart';

class IntergrationAddonContext extends AddonContext {
  IntergrationAddonContext(super.addon);

  @override
  List<SquirrelFunction> get functions => [];

  @override
  void test(YamlMap yaml) {
    return;
  }

  void launch(String endpoint) {
    final vm = startVM();
    vm.call("launch", args: [endpoint]);
    vm.dispose();
  }
}

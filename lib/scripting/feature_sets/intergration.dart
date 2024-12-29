import 'dart:ffi';
import '../addon.dart';
import '../squirrel.dart';
import '../squirrel_bindings_generated.dart';
import 'package:open_url/open_url.dart';

class IntergrationAddonContext extends AddonContext {
  IntergrationAddonContext(super.addon);

  @override
  List<SquirrelFunction> get functions => [
        SquirrelFunction("openURL", {"url": tagSQObjectType.OT_STRING},
            _openURLFromSquirrel),
      ];

  void launch(String endpoint) {
    final vm = startVM();
    Squirrel.call(vm, "launch", args: [endpoint]);
    Squirrel.dispose(vm);
  }

  void _openURLFromSquirrel(Pointer<SQVM> vm, Map<String, dynamic> params) {
    if ((params['url'] as String).startsWith("http://") ||
        (params['url'] as String).startsWith("https://")) {
      throw Exception(
          "Addon (${addon!.name}) tried to open a HTTP Url. For security reasons, HTTP addresses are not allowed to be opened. If you made this Addon, please use a different protocol (like 'steam://'). If you downloaded this Addon, please uninstall the addon and contact the author.");
    }
    openUrl(params['url'] as String);
  }
}

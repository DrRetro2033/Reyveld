import 'dart:io';

import 'package:reyveld/reyveld.dart';
import 'package:reyveld/scripting/sinterface.dart';
import 'package:yaml/yaml.dart';

class AppLauncher {
  static File get appDirFile => File("${Reyveld.appDataPath}/apps.yaml");

  /// Initializes the apps.yaml file.
  static Future<void> initialize() async {
    if (!await appDirFile.exists()) {
      await appDirFile.create(recursive: true);
      await appDirFile.writeAsString(
          """# This file contains all of the app paths that Reyveld can launch.

""");
    }
  }

  /// Returns a list of all of the apps that Reyveld can launch.
  static Future<List<(String, String)>> getApps() async {
    final content = await appDirFile.readAsString();
    final yaml = loadYaml(content);
    if (yaml is YamlMap) {
      return yaml.entries
          .map((e) => (e.key as String, e.value as String))
          .toList();
    } else {
      throw Exception("Invalid apps.yaml file.");
    }
  }

  static Future<void> addApp(String name, String path) async {
    final apps = await getApps();
    if (apps.any((e) => e.$1 == name)) throw Exception("App already exists.");
    apps.add((name, path));
    final content =
        """# This file contains all of the app paths that Reyveld can launch.
${apps.map((e) => "${e.$1}: ${e.$2}").join("\n")}""";
    try {
      loadYaml(content);
      await appDirFile.writeAsString(content);
    } catch (e) {
      throw Exception("App name and/pr path are invalid for YAML file.");
    }
  }

  static Future<void> removeApp(String name) async {
    final apps = await getApps();
    apps.removeWhere((e) => e.$1 == name);
    await appDirFile.writeAsString(
        """# This file contains all of the app paths that Reyveld can launch.
${apps.map((e) => "${e.$1}: ${e.$2}").join("\n")}""");
  }

  static Future<void> launchApp(String app, Iterable<String> args,
      {ProcessStartMode mode = ProcessStartMode.detached}) async {
    final apps = await getApps();
    final a = apps.where((e) => e.$1 == app);
    if (a.singleOrNull == null) {
      return;
    } else {
      await Process.start(a.single.$2, args.toList(), mode: mode);
    }
  }
}

class AppLauncherInterface extends SInterface<AppLauncher> {
  @override
  String get className => "AppLauncher";

  @override
  get statics => {
        LEntry(
            name: "addApp",
            descr: "Add an app to Reyveld.",
            isAsync: true,
            args: const {
              LArg<String>(name: "name"),
              LArg<String>(name: "path")
            },
            (String name, String path) async =>
                await AppLauncher.addApp(name, path)),
        LEntry(
            name: "removeApp",
            descr: "Remove an app from Reyveld.",
            isAsync: true,
            args: const {LArg<String>(name: "name")},
            (String name) async => await AppLauncher.removeApp(name)),
        LEntry(
          name: "launchApp",
          descr: "Launch an app from Reyveld.",
          isAsync: true,
          returnType: int,
          args: const {
            LArg<String>(name: "app"),
            LArg<List>(
                name: "args",
                kind: ArgKind.optionalPositional,
                docTypeOverride: "string[]")
          },
          securityCheck: """
return cert.hasPolicy(SPolicyLaunchApps)
""",
          (String app, [List args = const []]) async =>
              await AppLauncher.launchApp(app, args.whereType()),
        )
      };
}

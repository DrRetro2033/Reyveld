import 'dart:io';

import '/reyveld.dart';
import '/scripting/sinterface.dart';
import 'package:yaml/yaml.dart';

class AppLauncher {
  static File get appDirFile => File("${Reyveld.versionDataPath}/apps.yaml");

  static String _structure(String body) => """
# This file contains all of the app paths that Reyveld can launch.
$body
""";

  /// Initializes the apps.yaml file.
  static Future<void> initialize() async {
    if (!await appDirFile.exists()) {
      await appDirFile.create(recursive: true);
      await appDirFile.writeAsString(_structure(""));
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

  /// Adds an app.
  static Future<void> addApp(String name, String path) async {
    final apps = await getApps();
    if (apps.any((e) => e.$1 == name)) throw Exception("App already exists.");
    apps.add((name, path));
    final content = _structure(apps.map((e) => "${e.$1}: ${e.$2}").join("\n"));
    try {
      loadYaml(content);
      await appDirFile.writeAsString(content);
    } catch (e) {
      throw Exception("App name and/or path are invalid for YAML file.");
    }
  }

  /// Removes an app.
  static Future<void> removeApp(String name) async {
    final apps = await getApps();
    apps.removeWhere((e) => e.$1 == name);
    await appDirFile.writeAsString(
        _structure(apps.map((e) => "${e.$1}: ${e.$2}").join("\n")));
  }

  /// Checks if an app exists.
  static Future<bool> hasApp(String name) async =>
      (await getApps()).any((e) => e.$1 == name);

  /// Launches an app.
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
            name: "hasApp",
            descr: "Check if an app exists.",
            isAsync: true,
            args: const {LArg<String>(name: "name")},
            (String name) async => await AppLauncher.hasApp(name)),
        LEntry(
          name: "launchApp",
          descr: "Launch an app from Reyveld.",
          isAsync: true,
          returnType: int,
          args: const {
            LArg<String>(name: "app", descr: "The app to launch."),
            LArg<List>(
                name: "args",
                descr: "The arguments to pass to the app.",
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

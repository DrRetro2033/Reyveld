import "dart:io";

import "package:version/version.dart";

Future<void> main(List<String> args) async {
  final folder = args[0];
  final versionFile = File("$folder/version.txt");
  final appFile = File("$folder/lib/version.dart");
  final version = Version.parse(await versionFile.readAsString());
  // print(await appFile.exists());
  // print("Current version is $version");
  if (args.length > 1) {
    final command = args[1];
    Version newVersion = version;
    switch (command) {
      case "refresh":
        newVersion = Version(version.major, version.minor, version.patch,
            preRelease: version.preRelease);
      case "patch":
        newVersion = Version(version.major, version.minor, version.patch + 1,
            preRelease: version.preRelease);
      case "minor":
        newVersion = Version(version.major, version.minor + 1, 0,
            preRelease: version.preRelease);
      case "major":
        newVersion =
            Version(version.major + 1, 0, 0, preRelease: version.preRelease);
    }
    await versionFile.writeAsString(newVersion.toString());
    await appFile.writeAsString("""
import 'package:version/version.dart';

final currentVersion = Version(${newVersion.major}, ${newVersion.minor}, ${newVersion.patch}, preRelease: [${newVersion.preRelease.map((e) => "\"$e\"").join(", ")}]);""");
    print("Updated $version -> $newVersion!");
  }
}

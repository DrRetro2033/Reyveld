import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:arceus/arceus.dart';
import 'package:version/version.dart';

class Updater {
  static Version get currentVersion => Version(0, 0, 1, preRelease: ["alpha"]);
  static const String repoOwner = 'DrRetro2033';
  static const String repoName = 'Arceus';

  Future<bool> checkForUpdate({bool skip = true}) async {
    if (Arceus.isDev) {
      // Do not check for updates in development.
      return false;
    }
    final latestVersion = await getLatestVersion();
    if (latestVersion == null) {
      return false;
    }
    if (skip) {
      return false;
    }
    return latestVersion > currentVersion;
  }

  static Future<Version?>? getLatestVersion() async {
    try {
      final response = await http.get(
          Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/tags'));
      if (response.statusCode == 200) {
        final latestVersionTags = jsonDecode(response.body);
        if (latestVersionTags.isEmpty) {
          return null;
        }
        return Version.parse(latestVersionTags.first['name']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static String _getZipName() {
    if (Platform.isWindows) {
      return 'windows-latest.zip';
    } else if (Platform.isLinux) {
      return 'linux-latest.zip';
    } else if (Platform.isMacOS) {
      return 'macos-latest.zip';
    } else {
      return 'arceus.zip';
    }
  }

  static Future<void> update() async {
    final installPath = Arceus.appDataPath;
    try {
      final apiUrl = Uri.parse(
          'https://github.com/$repoOwner/$repoName/releases/download/v${getLatestVersion()}/${_getZipName()}');
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        Archive archive = ZipDecoder().decodeBytes(response.bodyBytes);
        for (ArchiveFile file in archive) {
          if (file.isFile) {
            final filePath = '$installPath/${file.name}';
            File(filePath).createSync(recursive: true);
            File(filePath).writeAsBytesSync(file.content);
          }
        }
        archive.clearSync();
      }
    } catch (e) {
      rethrow;
    }
  }
}

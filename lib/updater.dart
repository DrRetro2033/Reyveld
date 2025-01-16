import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:arceus/arceus.dart';
import 'package:version/version.dart';

class Updater {
  static Version get currentVersion => Version(1, 0, 0, preRelease: ["alpha"]);
  static const String repoOwner = 'DrRetro2033';
  static const String repoName = 'Arceus';

  /// Checks for available updates to the application.
  ///
  /// This function compares the current version of the application with the latest
  /// version available on the repository. It does not perform the check if the application
  /// is in development mode.
  ///
  /// If the [skip] parameter is set to `true`, the function will also compare the latest
  /// version with a previously skipped version and will not prompt an update if the latest
  /// version is older than or equal to the skipped version.
  ///
  /// Returns `true` if a newer version is available, otherwise `false`.
  Future<bool> checkForUpdate({bool skip = true}) async {
    // if (Arceus.isDev) {
    //   // Do not check for updates in development.
    //   return false;
    // }
    final latestVersion = await getLatestVersion();
    if (latestVersion == null) {
      return false;
    }
    if (skip && latestVersion <= Arceus.getSkippedVersion()) {
      return false;
    }
    return latestVersion > currentVersion;
  }

  /// Gets the latest version of the application from the GitHub repository.
  ///
  /// The function returns the latest version available on the repository, or `null`
  /// if the request fails or if there are no tags on the repository.
  ///
  /// The function does not throw any exceptions.
  static Future<Version?> getLatestVersion() async {
    try {
      final response = await http.get(
          Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/tags'));
      if (response.statusCode == 200) {
        final latestVersionTags = jsonDecode(response.body);
        if (latestVersionTags.isEmpty) {
          return null;
        }
        if (latestVersionTags.first['name'].startsWith('v')) {
          return Version.parse(latestVersionTags.first['name'].substring(1));
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
          'https://github.com/$repoOwner/$repoName/releases/download/v${getLatestVersion().toString()}/${_getZipName()}');
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

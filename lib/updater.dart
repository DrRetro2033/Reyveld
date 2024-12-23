import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'arceus.dart';

class Updater {
  String get currentVersion => Platform.version;
  static const String repoOwner = 'DrRetro2033';
  static const String repoName = 'Arceus';

  Future<bool> checkForUpdate({bool skip = true}) async {
    final latestVersion = await getLatestVersion();
    if (latestVersion == null) {
      return false;
    }
    if (skip && latestVersion == Arceus.getSkippedVersion()) {
      return false;
    }
    return latestVersion != currentVersion;
  }

  static Future<String?>? getLatestVersion() async {
    try {
      return await http
          .get(Uri.parse(
              'https://api.github.com/repos/$repoOwner/$repoName/releases/latest'))
          .then((response) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return (data['tag_name'] as String).substring(1);
        } else {
          return null;
        }
      });
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
    try {
      final apiUrl = Uri.parse(
          'https://github.com/$repoOwner/$repoName/releases/download/v${getLatestVersion()}/${_getZipName()}');
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/$repoName.zip');
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        await tempFile.writeAsBytes(response.bodyBytes);
        await Process.run('unzip', ['-o', tempFile.path, '-d', tempDir.path]);
        await Process.run(
            'cp', ['-r', '${tempDir.path}/$repoName', Arceus.appDataPath]);
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      return;
    }
  }
}

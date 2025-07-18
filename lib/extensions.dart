import 'dart:convert';
import 'dart:io';
import 'package:hashlib/hashlib.dart';
// import 'package:arceus/scripting/addon.dart';

Map<String, String> environment() {
  final env = <String, String>{};
  switch (Platform.operatingSystem) {
    case "windows":
      env["appdata"] = Platform.environment["APPDATA"]!;
      env["localappdata"] = Platform.environment["LOCALAPPDATA"]!;
    case "linux":
      env["appdata"] = Platform.environment['XDG_CONFIG_HOME'] ??
          '${Platform.environment['HOME']}/.config';
      env["localappdata"] = Platform.environment['XDG_DATA_HOME'] ??
          '${Platform.environment['HOME']}/.local/share';
    case "macos":
      env["appdata"] =
          '${Platform.environment['HOME']}/Library/Application Support';
      env["localappdata"] = env["appdata"]!;
  }
  return env;
}

extension Pathing on String {
  /// Fixes the path by converting windows formatting to an absolute path in unix format.
  /// This will also replace environment variables (e.g.`:appdata:`) with their values.
  ///
  /// This also parses platform tags. Platform tags can be used to have parts only be used on a specific platform.
  /// For example, `<win>':appdata:'`, will only be used if the platform running is on windows.
  ///
  /// You can add multiple tags in a part to switch depending on the platform (e.g. `<win>':appdata:'<lix>'home'/continued-path`).
  ///
  /// You can even add multiple platform tags to one path (e.g. `<lix,mac>'home'`)!
  ///
  /// Platform tags:
  ///  - win - for windows
  ///  - lix - for linux
  ///  - mac - for macos
  ///  - any - default
  String resolvePath() {
    String path = replaceAll("\\", "/");
    final platformTagExp = RegExp(r"<((?:\w{3},?)+)>'([\w\s\d:/-_]+)'");

    final parts = path.split("/");

    List<String> resolvedParts = [];

    resolve(String e) {
      String x = e.replaceAll("\\", "/");
      if (x.startsWith(":") && x.endsWith(":")) {
        final envVar = x.substring(1, x.length - 1);
        return environment()[envVar]!;
      }
      return x;
    }

    for (final part in parts) {
      final matches = platformTagExp.allMatches(part);
      if (matches.isNotEmpty) {
        String platformTag = "any";
        switch (Platform.operatingSystem) {
          case "windows":
            platformTag = "win";
          case "linux":
            platformTag = "lix";
          case "macos":
            platformTag = "mac";
        }
        for (final match in matches) {
          final tags = match.group(1)!.split(',');
          if (tags.contains(platformTag) || tags.contains("any")) {
            resolvedParts.add(resolve(match.group(2)!));
            break;
          }
        }
        continue;
      }
      resolvedParts.add(resolve(part));
    }
    return resolvedParts.join("/");
  }

  String relativeTo(String relativeTo) {
    final formattedPath = resolvePath();
    final formattedRelativeTo = relativeTo.resolvePath();
    return formattedPath.replaceFirst(formattedRelativeTo, "").resolvePath();
  }

  /// # `String` getFilename()
  /// ## Returns the filename of the string.
  /// The filename will be the same for both internal and external paths.
  String getFilename({bool withExtension = true}) {
    String path = resolvePath();
    if (withExtension) {
      return path.split("/").last;
    } else {
      return path.split("/").last.split(".").first;
    }
  }
}

extension ChunkStream on Stream<int> {
  Stream<List<int>> chunk(int chunkSize) async* {
    final List<int> buffer = [];
    await for (int byte in this) {
      buffer.add(byte);
      if (buffer.length == chunkSize) {
        yield buffer;
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) {
      yield buffer;
    }
  }
}

extension CreateParentDirectory on File {
  Future<void> ensureParentDirectory() async {
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    return;
  }
}

extension FileChecksum on File {
  Future<String> get checksum async => md5sum(await openRead()
      .transform(gzip.encoder)
      .transform(base64.encoder)
      .reduce((a, b) => a + b));
}

extension DirectoryChecksum on Directory {
  Future<String> get checksum async {
    List<String> checksums = [];
    await for (final file in list(recursive: true)) {
      if (file is File) {
        checksums.add(await file.checksum);
      }
    }
    return md5sum(checksums.join());
  }
}

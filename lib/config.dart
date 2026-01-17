import 'dart:io';
import 'package:ini/ini.dart';
import 'package:reyveld/extensions.dart';
import 'package:reyveld/extras.dart';
import 'package:reyveld/reyveld.dart';

/// Contains the settings and options for Reyveld.
class RConfig {
  static const String _defaultConfig = """
[performance]
READ&WRITEPOOL=20
LUAPOOL=2
SQLPOOL=8
LUAPOOL_TIMEOUT=1h
CHANGE_TRACKER_INTERVAL=1s

[other]
DISABLE_WELCOME_MESSAGE=False
""";

  static Future<Config> get _config async {
    final file = File(Reyveld.configPath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(_defaultConfig);
    }
    return Config.fromString(await file.readAsString());
  }

  static Future<String> getOption(String section, String option) =>
      _config.then((e) =>
          e.get(section, option) ??
          Config.fromString(_defaultConfig).get(section, option)!);

  static Future<int> getInt(String section, String option,
          {int? max, int? min}) async =>
      int.parse(await getOption(section, option))
          .keepInRange(min: min, max: max);

  static Future<bool> getBool(String section, String option) async =>
      await getOption(section, option) == "True";

  static Future<Duration> getDuration(String section, String option) async =>
      parseDurationFromString(await getOption(section, option));

  /// Returns the maximum number of concurrent read-write operations.
  static Future<int> get readWritePool =>
      getInt("performance", "READ&WRITEPOOL", min: 1);

  /// Returns the maximum number of concurrent Lua operations.
  static Future<int> get luaPool => getInt("performance", "LUAPOOL", min: 1);

  /// Returns the maximum number of concurrent SQL operations.
  static Future<int> get sqlPool => getInt("performance", "SQLPOOL", min: 1);

  /// Returns the timeout for Lua operations.
  static Future<Duration> get luaPoolTimeout =>
      getDuration("performance", "LUAPOOL_TIMEOUT");

  static Future<bool> get disableWelcomeMessage async =>
      await getBool("other", "DISABLE_WELCOME_MESSAGE");

  static Future<Duration> get defaultTrackerInterval =>
      getDuration("performance", "CHANGE_TRACKER_INTERVAL");
}

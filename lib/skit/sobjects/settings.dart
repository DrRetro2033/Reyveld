// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:arceus/extensions.dart';
import 'package:arceus/serekit/sobject.dart';

part 'settings.g.dart';

@SGen("settings")
class ArceusSettings extends SObject {
  ArceusSettings(super.kit, super.node);

  DateFormat get dateFormat =>
      DateFormat.values[int.tryParse(get("date-format") ?? "0") ?? 0];

  set dateFormat(DateFormat value) =>
      set("date-format", value.index.toString());

  TimeFormat get timeFormat =>
      TimeFormat.values[int.tryParse(get("time-format") ?? "0") ?? 0];

  set timeFormat(TimeFormat value) =>
      set("time-format", value.index.toString());

  DateSize get dateSize =>
      DateSize.values[int.tryParse(get("date-size") ?? "0") ?? 0];

  set dateSize(DateSize value) => set("date-size", value.index.toString());

  bool get debugMode => (get("debug") ?? "1") == "1";
  set debugMode(bool value) => set("debug", value ? "1" : "0");

  /// Saves the SKit.
  Future<void> save() async => await kit.save();

  @override
  String get displayName => "Settings ⚙️";
}

class ArceusSettingsCreator extends SCreator<ArceusSettings> {
  @override
  get creator => (builder) {
        builder.attribute("date-format", DateFormat.dayMonthYear.index);
        builder.attribute("time-format", TimeFormat.h12.index);
        builder.attribute("date-size", DateSize.regular.index);
        builder.attribute("debug", "1");
      };
}

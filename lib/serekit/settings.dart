import 'dart:async';

import 'package:arceus/serekit/serekit.dart';

part 'settings.g.dart';

class ArceusSettings extends SObject {
  ArceusSettings(super.kit, super.node);

  DateFormat get dateFormat => DateFormat.values
      .firstWhere((e) => e.index == int.tryParse(get("date-format") ?? "0"));

  set dateFormat(DateFormat value) =>
      set("date-format", value.index.toString());

  TimeFormat get timeFormat => TimeFormat.values
      .firstWhere((e) => e.index == int.tryParse(get("time-format") ?? "0"));

  set timeFormat(TimeFormat value) =>
      set("time-format", value.index.toString());

  /// Saves the SKit.
  Future<void> save() async => await kit.save();

  String formatDate(DateTime date) {
    switch (dateFormat) {
      case DateFormat.dayMonthYear:
        return "${date.day}/${date.month}/${date.year}";
      case DateFormat.monthDayYear:
        return "${date.month}/${date.day}/${date.year}";
    }
  }

  String formatTime(DateTime date) {
    switch (timeFormat) {
      case TimeFormat.h12:
        return "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
      case TimeFormat.h24:
        return "${date.hour}:${date.minute}";
    }
  }
}

enum DateFormat { dayMonthYear, monthDayYear }

enum TimeFormat { h12, h24 }

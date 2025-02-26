// ignore_for_file: constant_identifier_names

import 'dart:async';

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

  String formatDate(DateTime date) {
    switch (dateSize) {
      case DateSize.regular:

        /// Regular
        final day = _formatDay(date.day);
        final month = Months.values[date.month - 1].name;
        switch (dateFormat) {
          case DateFormat.dayMonthYear:
            return "$day $month, ${date.year}";
          case DateFormat.monthDayYear:
            return "$month $day, ${date.year}";
        }
      case DateSize.condenced:

        /// Condenced
        switch (dateFormat) {
          case DateFormat.dayMonthYear:
            return "${date.day}/${date.month}/${date.year}";
          case DateFormat.monthDayYear:
            return "${date.month}/${date.day}/${date.year}";
        }
    }
  }

  String _formatDay(int day) {
    if (day == 1) {
      return "1st";
    }
    if (day == 2) {
      return "2nd";
    }
    if (day == 3) {
      return "3rd";
    }
    return "${day}th";
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

class ArceusSettingsCreator extends SCreator<ArceusSettings> {
  @override
  get creator => (builder) {
        builder.attribute("date-format", DateFormat.dayMonthYear.index);
        builder.attribute("time-format", TimeFormat.h12.index);
        builder.attribute("date-size", DateSize.regular.index);
        builder.attribute("debug", "1");
      };
}

enum DateSize { regular, condenced }

enum DateFormat { dayMonthYear, monthDayYear }

enum TimeFormat { h12, h24 }

enum Months {
  January,
  February,
  March,
  April,
  May,
  June,
  July,
  August,
  September,
  October,
  November,
  December
}

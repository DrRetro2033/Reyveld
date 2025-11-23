import '/scripting/sinterface.dart';

class DateTimeInterface extends SInterface<DateTime> {
  @override
  String get className => "DateTime";

  @override
  String get classDescription => "A date and time.";

  @override
  get exports => {
        LEntry(
            name: "ms",
            descr: "The millisecond of the date.",
            returnType: int,
            () => object!.millisecond),
        LEntry(
            name: "s",
            descr: "The second of the date.",
            returnType: int,
            () => object!.second),
        LEntry(
            name: "m",
            descr: "The minute of the date.",
            returnType: int,
            () => object!.minute),
        LEntry(
            name: "h",
            descr: "The hour of the date.",
            returnType: int,
            () => object!.hour),
        LEntry(
            name: "d",
            descr: "The day of the date.",
            returnType: int,
            () => object!.day),
        LEntry(
            name: "y",
            descr: "The year of the date.",
            returnType: int,
            () => object!.year),
        LEntry(
            name: "weekday",
            descr: "The weekday of the date.",
            returnType: int,
            () => object!.weekday),
        LEntry(
            name: "string",
            descr: "The date as a string.",
            returnType: String,
            () => object!.toString()),
      };
}

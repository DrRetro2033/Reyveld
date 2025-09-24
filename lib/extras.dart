/// Parses a string into a [Duration].
///
/// The string should be in the format: [quantity][unit] [quantity][unit] ...
/// where quantity is an integer and unit is one of: d, h, m, s, ms, mc
/// Example: 1d2h3m4s5ms6mc
Duration parseDurationFromString(String value) {
  RegExp exp = RegExp(r'([0-9])([dhmscw]*)');
  final matches = exp.allMatches(value);
  Duration duration = Duration();
  for (final match in matches) {
    final quantity = int.parse(match.group(1)!);
    final unit = match.group(2)!;
    switch (unit) {
      case "d":
        duration += Duration(days: quantity);
      case "h":
        duration += Duration(hours: quantity);
      case "m":
        duration += Duration(minutes: quantity);
      case "s":
        duration += Duration(seconds: quantity);
      case "ms":
        duration += Duration(milliseconds: quantity);
      case "mc":
        duration += Duration(microseconds: quantity);
    }
  }
  return duration;
}

import 'package:arceus/main.dart';
import 'package:arceus/serekit/sobjects/settings.dart';
import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:interact/interact.dart';

class SettingsCommand extends Command {
  @override
  String get name => "settings";

  @override
  String get description => "Adjust different settings in Arceus.";

  @override
  Future<void> run() async {
    final exitOptions = [
      "Save and Exit",
      "Exit"
    ]; // options for the exiting settings
    final options = [
      "Date Format",
      "Time Format"
    ]; // available options to change
    while (true) {
      final selection =
          Select(prompt: "Settings", options: [...options, ...exitOptions])
              .interact();
      switch (selection) {
        case 0:
          final newFormat = Select(
                  prompt: "Date Format",
                  options: ["Day/Month/Year", "Month/Day/Year", "Cancel"],
                  initialIndex: settings!.dateFormat.index)
              .interact();
          switch (newFormat) {
            case 0:
              settings!.dateFormat = DateFormat.dayMonthYear;
            case 1:
              settings!.dateFormat = DateFormat.monthDayYear;
            case 2:
              continue;
          }
        case 1:
          final newFormat = Select(
                  prompt: "Time Format",
                  options: ["12-hour", "24-hour", "Cancel"],
                  initialIndex: settings!.timeFormat.index)
              .interact();
          switch (newFormat) {
            case 0:
              settings!.timeFormat = TimeFormat.h12;
            case 1:
              settings!.timeFormat = TimeFormat.h24;
            case 2:
              continue;
          }
        default:
          if (selection >= options.length) {
            final exitSelected = selection - options.length;
            if (exitSelected == 0) {
              final spinner =
                  CliSpin(text: "Saving...", spinner: CliSpinners.moon).start();
              await settings!.save();
              spinner.success("Saved settings!");
              return;
            } else if (exitSelected == 1) {
              return;
            }
          }
      }
    }
  }
}

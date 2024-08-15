import 'dart:io';

import 'package:interact/interact.dart';
import 'package:dart_console/dart_console.dart';
import 'main.dart';

class Cli {
  static Console console = Console();
  static int _indent = 0;
  static int get indent => _indent;

  static void run() {
    console.clearScreen();
    console.writeLine("Welcome to Arceus!");
    _mainMenu(arceus.isEmpty);
  }

  static void indentRight() {
    _indent++;
  }

  static void indentLeft() {
    _indent--;
  }

  static void _mainMenu(bool hasGames) {
    while (true) {
      console.writeLine("Arceus v0.0.1");
      if (!hasGames) {
        final selection =
            Select(prompt: "Select an option:", options: ["Add Game", "Exit"])
                .interact();
        switch (selection) {
          case 0:
            final name = Input(prompt: "Game Name:").interact();
            final path = Input(
              prompt: "Game Path:",
              validator: (p0) {
                p0 = p0.replaceAll("\"", "");
                p0 = p0.replaceAll("\\", "/");
                if (p0.isNotEmpty && Directory(p0).existsSync()) {
                  return true;
                }
                return false;
              },
            ).interact();
            arceus.addGame(name, path);
          case 1:
            exit(0);
        }
      }
      console.clearScreen();
    }
  }
}

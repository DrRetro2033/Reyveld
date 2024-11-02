import 'dart:io';

import 'package:ansix/ansix.dart';

class Cli {
  static AnsiTreeViewTheme get treeTheme => AnsiTreeViewTheme(
      compact: true,
      headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
      keyTheme: AnsiTreeNodeKeyTheme(textStyle: AnsiTextStyle(bold: true)),
      valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
      anchorTheme: AnsiTreeAnchorTheme(
          style: AnsiBorderStyle.rounded, color: AnsiColor.magenta));

  static void clearTerminal() {
    if (Platform.isWindows) {
      // Use 'cls' for Windows
      // Process.runSync("cls", [], runInShell: true);
      stdout.write('\x1B[2J\x1B[0;0H');
    } else {
      // ANSI escape code to clear the terminal for Unix-based systems
      Process.runSync("clear", [], runInShell: true);
    }
  }
}

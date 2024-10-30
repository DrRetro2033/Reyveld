import 'package:ansix/ansix.dart';

class Cli {
  static AnsiTreeViewTheme get treeTheme => AnsiTreeViewTheme(
      compact: true,
      headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
      keyTheme: AnsiTreeNodeKeyTheme(textStyle: AnsiTextStyle(bold: true)),
      valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
      anchorTheme: AnsiTreeAnchorTheme(
          style: AnsiBorderStyle.rounded, color: AnsiColor.magenta));
}

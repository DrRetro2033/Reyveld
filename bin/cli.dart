import 'package:ansix/ansix.dart';

class Cli {
  static AnsiTreeViewTheme get treeTheme => AnsiTreeViewTheme(
      headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
      valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
      anchorTheme: AnsiTreeAnchorTheme(
          style: AnsiBorderStyle.rounded, color: AnsiColor.magenta));
}

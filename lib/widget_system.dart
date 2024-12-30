import 'dart:io';

import 'package:arceus/cli.dart';
import 'package:chalkdart/chalkstrings.dart';

class Size {
  final int width;
  final int height;

  Size(this.width, this.height);
}

abstract class Widget {
  void render(Size size);
}

class Row extends Widget {
  final List<Widget> children;

  Row(this.children);

  @override
  void render(Size size) {
    int childWidth = size.width ~/ children.length;
    for (var child in children) {
      child.render(Size(childWidth, size.height));
    }
    print('');
  }
}

class Column extends Widget {
  final List<Widget> children;

  Column(this.children);

  @override
  void render(Size size) {
    int childHeight = size.height ~/ children.length;
    for (var child in children) {
      child.render(Size(size.width, childHeight));
    }
  }
}

class Grid extends Widget {
  final List<List<Widget>> children;

  Grid(this.children);

  @override
  void render(Size size) {
    int rowHeight = size.height ~/ children.length;
    for (var row in children) {
      int colWidth = size.width ~/ row.length;
      for (var child in row) {
        child.render(Size(colWidth, rowHeight));
      }
      print('');
    }
  }
}

class Header extends Widget {
  final String text;

  Header(this.text);

  @override
  void render(Size size) {
    Cli.moveCursorToTopLeft();
    print(text.padRight(size.width));
  }
}

class Footer extends Widget {
  final String text;

  Footer(this.text);

  @override
  void render(Size size) {
    Cli.moveCursorToBottomLeft(text.split('\n').length);
    print(text.padRight(size.width));
  }
}

class Badge {
  final String text;

  final String badgeColor;
  final String textColor;
  Badge(this.text, {this.badgeColor = "white", this.textColor = "black"});

  @override
  String toString() {
    String badge = "";
    badge += ''.keyword(badgeColor);
    badge += text.keyword(textColor).onKeyword(badgeColor);
    badge += ''.keyword(badgeColor);
    return badge;
  }
}

class TreeWidget {
  final Map<dynamic, dynamic> data;
  final String pipeColor;
  final int padding;
  TreeWidget(
    this.data, {
    this.pipeColor = "blueviolet",
    this.padding = 2,
  });

  @override
  String toString() {
    return _createTree(data, 0, {});
  }

  String _createTree(
      Map<dynamic, dynamic> data, int level, Set<int> levelsEnded) {
    StringBuffer buffer = StringBuffer();
    List keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      bool isLast = i == keys.length - 1;
      if (isLast) {
        levelsEnded.add(level);
      }
      String? prefix;
      if (level <= 0) {
        prefix = '─── ';
        levelsEnded.add(0);
      } else {
        String pipes = '';
        for (int j = 0; j < level; j++) {
          if (levelsEnded.contains(j)) {
            pipes += '    '.padLeft(4 + padding);
          } else {
            pipes += '│   '.padLeft(4 + padding);
          }
        }
        prefix =
            "$pipes${isLast ? '╰── '.padLeft(4 + padding) : '├── '.padLeft(4 + padding)}";
      }

      buffer.writeln('${prefix.keyword(pipeColor)}$key');
      if (data[key] is Map) {
        if (data[key].isNotEmpty) {
          buffer.write(_createTree(data[key], level + 1, levelsEnded));
        }
      }
    }
    return buffer.toString();
  }
}

class TextWidget extends Widget {
  final String text;

  TextWidget(this.text);

  @override
  void render(Size size) {
    stdout.write(text.padRight(size.width));
  }
}

class WidgetSystem {
  final Widget rootWidget;

  WidgetSystem(this.rootWidget);

  void render() {
    Cli.clearTerminal();
    int width = stdout.terminalColumns;
    int height = stdout.terminalLines;
    rootWidget.render(Size(width, height));
  }
}

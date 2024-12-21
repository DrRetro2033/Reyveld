import 'dart:io';

import 'package:arceus/cli.dart';

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

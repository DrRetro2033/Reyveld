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
    return _createTree(data);
  }

  String _createTree(Map<dynamic, dynamic> data) {
    return MapLevel(data).toString();
  }
}

abstract class Level {
  final String? name;

  final int padding;
  String get pipeColor => "blueviolet";
  String get pipe => '│';
  String get startPipe => '╭';
  String get junctionPipe => '├';
  String get endPipe => '╰';

  Level({this.padding = 2, this.name});

  StringBuffer build();

  @override
  String toString() => build().toString();
}

class MapLevel extends Level {
  final Map<dynamic, dynamic> data;
  MapLevel(this.data, {super.padding, super.name});

  @override
  StringBuffer build() {
    StringBuffer buffer = StringBuffer();
    List keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      bool isFirst = i == 0;
      bool isLast = i == keys.length - 1;
      bool isSingle = keys.length == 1;
      String prefix;
      if (isFirst && name == null && !isSingle) {
        prefix = '$startPipe── ';
      } else if (isSingle && name == null) {
        prefix = '─── ';
      } else if (isLast) {
        prefix = '$endPipe── ';
      } else {
        prefix = '$junctionPipe── ';
      }
      if (data[key] is Map) {
        buffer.writeln('${prefix.keyword(pipeColor)}$key');
        StringBuffer x = MapLevel(data[key], name: key).build();
        if (x.isEmpty) {
          continue;
        }
        String pad = '${pipe.keyword(pipeColor)}   ';
        if (isLast || isSingle) {
          pad = '    ';
        }
        x.toString().split('\n').forEach((element) {
          buffer.writeln('$pad$element');
        });
      } else {
        buffer.writeln('${prefix.keyword(pipeColor)}$key: ${data[key]}');
      }
    }
    return buffer;
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

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:ansix/ansix.dart';
import 'package:dart_console/dart_console.dart';

class Cli {
  /// # static `int` get windowWidth
  /// ## Returns the width of the terminal.
  static int get windowWidth => stdout.terminalColumns;

  /// # static `int` get windowHeight
  /// ## Returns the height of the terminal.
  static int get windowHeight => stdout.terminalLines;

  // static int _lastWindowWidth = 0;
  // static int _lastWindowHeight = 0;

  /// # static `AnsiTreeViewTheme` get treeTheme
  /// ## Returns the theme for the tree view.
  /// Used when printing a tree view.
  static AnsiTreeViewTheme get treeTheme => AnsiTreeViewTheme(
      compact: true,
      headerTheme: AnsiTreeHeaderTheme(hideHeader: true),
      keyTheme: AnsiTreeNodeKeyTheme(textStyle: AnsiTextStyle(bold: true)),
      valueTheme: AnsiTreeNodeValueTheme(hideIfEmpty: true),
      anchorTheme: AnsiTreeAnchorTheme(
          style: AnsiBorderStyle.rounded, color: AnsiColor.magenta));

  /// # static `void` clearTerminal()
  /// ## Clears the terminal.
  static void clearTerminal() {
    if (Platform.isWindows) {
      // Use 'cls' for Windows
      // Process.runSync("cls", [], runInShell: true);
      stdout.write('\x1B[2J\x1B[0;3J');
    } else {
      // ANSI escape code to clear the terminal for Unix-based systems
      Process.runSync("clear", [], runInShell: true);
    }
  }

  /// # static `void` moveCursorToTopLeft()
  /// ## Moves the cursor to the top left of the terminal.
  static void moveCursorToTopLeft() {
    stdout.write("\x1B[1;1H");
  }

  /// # static `void` moveCursorToTopRight()
  /// ## Moves the cursor to the top right of the terminal.
  static void moveCursorToTopRight() {
    stdout.write("\x1B[1;${stdout.terminalColumns}H");
  }

  /// # static `void` moveCursorToBottomLeft()
  /// ## Moves the cursor to the bottom left of the terminal.
  static void moveCursorToBottomLeft([int offset = 0]) {
    stdout.write("\x1B[${stdout.terminalLines - offset};1H");
  }

  /// # static `void` moveCursorToBottomRight()
  /// ## Moves the cursor to the bottom right of the terminal.
  static void moveCursorToBottomRight() {
    stdout.write(
        "\x1B[${stdout.terminalLines - 1};${stdout.terminalColumns - 1}");
  }

  /// # static `void` hideCursor()
  /// ## Hides the cursor.
  static void hideCursor() {
    stdout.write("\x1B[?25l");
  }

  /// # static `void` showCursor()
  /// ## Shows the cursor.
  static void showCursor() {
    stdout.write("\x1B[?25h");
  }

  // static Stream<bool?> get resizeEvent =>
  //     Stream.periodic(Duration(milliseconds: 100), (_) {
  //       if (_lastWindowWidth != stdout.terminalColumns ||
  //           _lastWindowHeight != stdout.terminalLines) {
  //         _lastWindowWidth = stdout.terminalColumns;
  //         _lastWindowHeight = stdout.terminalLines;
  //         return true;
  //       }
  //       return null;
  //     });
}

/// # `KeyboardInput`
/// ## Keyboard input handler
/// Do NOT create two instances of this class at the same time, as it will cause synchronization issues.
class KeyboardInput {
  static final Console _console = Console();
  Isolate? _isolate;
  Capability? _cap;
  final StreamController<Key> _controller = StreamController<Key>();

  KeyboardInput() {
    _initialize();
  }

  /// # `Stream<Key>` get onKeyPress
  /// ## Returns the stream of key press events.
  /// Add listeners to this stream to handle key presses.
  Stream<Key> get onKeyPress => _controller.stream;

  /// # `void` _initialize()
  /// ## Initializes the keyboard input handler.
  /// Does not need to be called manually.
  void _initialize() async {
    // if (stdin.hasTerminal) {
    //   stdin.echoMode = false;
    //   stdin.lineMode = false;
    // }

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_listenForInput, receivePort.sendPort);
    receivePort.listen((key) {
      _controller.add(key);
    });
  }

  /// # `void` _listenForInput(SendPort sendPort)
  /// ## Listens for key presses and sends them to the given send port.
  static void _listenForInput(SendPort sendPort) {
    while (true) {
      final key = _console.readKey();
      sendPort.send(key);
    }
  }

  /// # `void` dispose()
  /// ## Disposes of the keyboard input handler.
  void dispose() {
    _controller.close();
    _isolate?.kill();
    _isolate = null;
    _cap = null;
    _controller.close();
  }

  /// # `void` pause()
  /// ## Pauses the keyboard input handler.
  void pause() {
    _cap = _isolate?.pause();
  }

  /// # `void` resume()
  /// ## Resumes the keyboard input handler.
  void resume() {
    _isolate?.resume(_cap!);
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:chalkdart/chalkstrings.dart';
import 'package:dart_console/dart_console.dart';
import '../cli.dart';
import '../version_control/dossier.dart';

enum Views {
  jumpToAddress, // For jumping to an address.
  byteViewer, // For moving through the file byte by byte.
  dataFooter, // For editing data visible in the footer.
  changeLog, // For looking at the change log. TODO: Needs to be implemented.
}

enum Formats {
  u8,
  u16,
  u32,
  u64
} // The data formats bytes can be displayed and edited in.

class HexEditor {
  /// # final `Plasma` _primaryFile
  /// ## The file being edited.
  final Plasma _primaryFile;

  /// # final `Plasma?` _secondaryFile
  /// ## The older version of the file being used for comparison.
  Plasma? _secondaryFile;

  /// # final `Map<int, int>` differences
  /// ## The differences between the primary file and the secondary file.
  Map<int, int> differences = {};

  /// # final `KeyboardInput` keyboard
  /// ## The keyboard input handler.
  final keyboard = KeyboardInput();

  /// # `Views` currentView
  /// ## The current view of the editor.
  /// Defaults to `Views.byteViewer`.
  Views currentView = Views.byteViewer;

  /// # `ByteData` data
  /// ## The data being edited.
  /// Returns the primary file's data.
  ByteData get data => _primaryFile.data;

  /// # `Endian` dataEndian
  /// ## The endianness of the data.
  /// Defaults to `Endian.little`.
  Endian dataEndian = Endian.little;

  /// # static const `int` _minDataHeight`
  /// ## The minimum height of everything other than the byte viewer.
  /// Should be replaced with something more dynamic.
  static const int _minDataHeight = 7;

  /// # `int` address
  /// ## The current address being viewed/edited.
  int address = 0;

  /// # `Formats` currentFormat
  /// ## The current format of the data being edited.
  Formats currentFormat = Formats.u8;

  /// # `String?` _currentValue
  /// ## The current value being inputed.
  /// Used for the `dataFooter` and `jumpToAddress` views.
  String? _currentValue;

  /// # `bool` error
  /// ## Whether or not an error has occurred.
  bool error = false;

  /// # `List<int>` byteColor
  /// ## The color label for a byte.
  final List<int> byteColor = [255, 255, 255];

  /// # `List<int>` byte16Color
  /// ## The color label for a 16-bit range.
  final List<int> byte16Color = [140, 140, 140];

  /// # `List<int>` byte32Color
  /// ## The color label for a 32-bit range.
  final List<int> byte32Color = [100, 100, 100];

  /// # `List<int>` byte64Color
  /// ## The color label for a 64-bit range.
  final List<int> byte64Color = [80, 80, 80];

  HexEditor(this._primaryFile) {
    if (_primaryFile.isTracked()) {
      _secondaryFile = _primaryFile.findOlderVersion();
      differences = _primaryFile.getDifferences(_secondaryFile!);
    }
  }

  /// # `String` getByteAt(int address)
  /// ## Get the byte at the given address as a hex string.
  String getByteAt(int address) {
    return data.getUint8(address).toRadixString(16).padLeft(2, "0");
  }

  /// # `bool` isValidAddress(int address)
  /// ## Check if an address is valid.
  bool isValidAddress(int address) {
    return address >= 0 && address < data.lengthInBytes;
  }

  /// # `void` render()
  /// ## Render the current state of the editor to the console.
  void render() {
    Cli.moveCursorToTopLeft();
    Cli.clearTerminal();
    // console.clearScreen();

    Cli.moveCursorToTopLeft();
    stdout.write(_primaryFile.getFilename().italic);
    if (_primaryFile.isTracked()) {
      stdout.write(" (Tracked)");
    }
    if (currentView == Views.byteViewer) {
      stdout.write(" - Ctrl+Q to quit. Ctrl+S to save.");
    }

    stdout.writeln();
    stdout.write(renderBody());
    stdout.writeln();

    // Write address at bottom left.
    Cli.moveCursorToBottomLeft();
    stdout.write("A".underline.bold);
    stdout.write("ddress: ");
    if (currentView == Views.jumpToAddress) {
      if (_currentValue != null) {
        int? x;
        if (_currentValue!.startsWith("0x")) {
          x = int.tryParse(_currentValue!.substring(2), radix: 16);
        } else {
          x = int.tryParse(_currentValue!);
        }

        if (x != null && x >= 0 && x < data.lengthInBytes) {
          stdout.write(_currentValue!.bgBrightMagenta.black);
        } else {
          stdout.write(_currentValue!.bgBrightRed.black);
          error = true;
        }
      } else {
        stdout.write("0x${address.toRadixString(16)}".bgBrightMagenta.black);
      }
    } else {
      stdout.write("0x${address.toRadixString(16)}");
    }
    stdout.write(" ");
    stdout.write(getValues(address));
  }

  /// # `String` renderBody()
  /// ## Render the bytes as the body of the editor.
  String renderBody() {
    final full = StringBuffer();
    final body = StringBuffer();

    // Calculate start and end lines
    int usableRows = Cli.windowHeight - _minDataHeight;
    int linesAboveBelow = usableRows ~/ 2;
    int startLine = (address ~/ 16) - linesAboveBelow;
    int endLine = (address ~/ 16) + linesAboveBelow;

    // Adjust start and end to ensure full screen is used
    if (startLine < 0) {
      startLine = 0;
      endLine = startLine + usableRows;
    } else if (endLine >= ((data.lengthInBytes / 16).ceil())) {
      endLine = (data.lengthInBytes / 16).ceil();
      startLine = endLine - usableRows;
      if (startLine < 0) startLine = 0; // Ensure we don't go below zero
    }

    full.write("\t\t00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f\n"
        .padLeft(8, " ")); // Address Headers
    for (int x = startLine * 16 < 0 ? 0 : startLine * 16;
        x < data.lengthInBytes && x < endLine * 16;
        x += 16) {
      // 16 bytes per line, with a gap between every eight bytes.
      final line = StringBuffer(""); // The line to be printed
      line.write("${x.toRadixString(16).padLeft(8, "0")}\t"); // Address Labels
      for (int leftHalf = 0; leftHalf < 8; leftHalf++) {
        // Left Half of 16 bytes
        int byteAddress = x + leftHalf;
        if (!isValidAddress(byteAddress)) {
          line.write("  ");
        } else {
          String byte = getByteAt(byteAddress);
          String value = getFormatted(byteAddress, byte);
          line.write(value);
        }
        if (leftHalf != 7) {
          line.write(isValidAddress(byteAddress) ? "│" : " ");
        }
      }
      line.write(" ");
      // Checks to see if there is a second half of 8 bytes
      for (int rightHalf = 8; rightHalf < 16; rightHalf++) {
        // Right Half of 16 bytes
        int byteAddress = x + rightHalf;
        if (!isValidAddress(byteAddress)) {
          line.write("  ");
        } else {
          String byte = getByteAt(byteAddress);
          String value = getFormatted(byteAddress, byte);
          line.write(value);
        }
        if (rightHalf != 15) {
          line.write(isValidAddress(byteAddress) ? "│" : " ");
        }
      }
      line.write("\t│");
      for (int j = 0; j < 16; j++) {
        if (isValidAddress(x + j)) {
          final char = data.getUint8(x + j);
          final charString =
              _isPrintable(char) ? String.fromCharCode(char) : '.';
          line.write(getFormatted(x + j, charString));
        } else {
          line.write(' ');
        }
      }
      body.write("${line.toString()}\n");
    }
    if (startLine != 0) {
      //Notifies user that there is more data above
      full.write("\t".padLeft(16, " "));
      full.write("───────────────────────^───────────────────────\n");
    } else {
      full.write("\n");
    }
    full.write(body.toString());
    if (endLine < ((data.lengthInBytes / 16).ceil())) {
      //Notifies user that there is more data below
      full.write("\t".padLeft(16, " "));
      full.write("───────────────────────v───────────────────────\n");
    } else {
      full.write("\n");
    }
    return full.toString();
  }

  /// # `String` getValues(int byteAddress)
  /// ## Get the values of the different formats at the given address.
  /// The values are formatted as a string with the header in the corresponding
  /// color and the value in the same color.
  /// If the current view is the data footer, the current format is highlighted.
  /// If the current view is not the data footer, it adds a note to press E to
  /// edit any of these values.
  String getValues(int byteAddress) {
    StringBuffer values = StringBuffer();
    for (Formats format in Formats.values) {
      // Add all the formats to the values buffer.
      error = false;
      String? value;
      String? header;
      switch (format) {
        case Formats.u8:
          header = "u8".bgRgb(byteColor[0], byteColor[1], byteColor[2]).black;
          if (currentFormat == Formats.u8 && _currentValue != null) {
            if (int.tryParse(_currentValue!) != null) {
              int x = int.tryParse(_currentValue!)!;
              if (x.toRadixString(2).length > 8 || x < 0) {
                error = true;
              }
            } else {
              error = true;
            }
            value = _currentValue.toString();
          } else {
            value = data.getUint8(address).toString();
          }
          break;
        case Formats.u16:
          if (isValidAddress(byteAddress + 1)) {
            header = "u16"
                .bgRgb(byte16Color[0], byte16Color[1], byte16Color[2])
                .black;
            if (currentFormat == Formats.u16 && _currentValue != null) {
              if (int.tryParse(_currentValue!) != null) {
                int x = int.tryParse(_currentValue!)!;
                if (x.toRadixString(2).length > 16 || x < 0) {
                  error = true;
                }
              } else {
                error = true;
              }
              value = _currentValue.toString();
            } else {
              value = data.getUint16(address, dataEndian).toString();
            }
          }
          break;
        case Formats.u32:
          if (isValidAddress(byteAddress + 3)) {
            header = "u32"
                .bgRgb(byte32Color[0], byte32Color[1], byte32Color[2])
                .black;
            if (currentFormat == Formats.u32 && _currentValue != null) {
              if (int.tryParse(_currentValue!) != null) {
                int x = int.tryParse(_currentValue!)!;
                if (x.toRadixString(2).length > 32 || x < 0) {
                  error = true;
                }
              } else {
                error = true;
              }
              value = _currentValue.toString();
            } else {
              value =
                  data.getUint32(address, dataEndian).toStringAsExponential(2);
            }
          }
          break;
        case Formats.u64:
          if (isValidAddress(byteAddress + 7)) {
            header = "u64"
                .bgRgb(byte64Color[0], byte64Color[1], byte64Color[2])
                .black;
            if (currentFormat == Formats.u64 && _currentValue != null) {
              if (int.tryParse(_currentValue!) != null) {
                int x = int.tryParse(_currentValue!)!;
                if (x.toRadixString(2).length > 64 || x < 0) {
                  error = true;
                }
              } else {
                error = true;
              }
              value = _currentValue.toString();
            } else {
              value =
                  data.getUint64(address, dataEndian).toStringAsExponential(2);
            }
          }
          break;
      }
      if (value == null || header == null) {
        continue;
      }
      if (currentView == Views.dataFooter && currentFormat == format) {
        if (!error) {
          value = value.bgMagentaBright.black;
        } else {
          value = value.bgRedBright.black;
        }
      }
      values.write("$header $value| ");
    }
    if (currentView != Views.dataFooter) {
      values.write("Press E to edit any of these values.");
    }
    return values.toString();
  }

  /// # `String` getFormatted(int byteAddress, String value)
  /// ## Get the values of the different formats at the given address.
  /// The values are formatted as a string with the header in the corresponding color.
  String getFormatted(int byteAddress, String value) {
    if (byteAddress == address) {
      value = value.bgRgb(byteColor[0], byteColor[1], byteColor[2]).black;
    } else if (byteAddress == address + 1) {
      value = value.bgRgb(byte16Color[0], byte16Color[1], byte16Color[2]).black;
    } else if (byteAddress >= address + 2 && byteAddress <= address + 3) {
      value = value.bgRgb(byte32Color[0], byte32Color[1], byte32Color[2]).black;
    } else if (byteAddress >= address + 4 && byteAddress <= address + 7) {
      value = value.bgRgb(byte64Color[0], byte64Color[1], byte64Color[2]).black;
    }
    if (_primaryFile.unsavedChanges().containsKey(byteAddress)) {
      value = value.brightYellow;
    } else if (differences.containsKey(byteAddress)) {
      value = value.brightCyan;
    }
    return value;
  }

  /// # `bool` _isPrintable(int charCode)
  /// ## Check if the given character code is printable.
  /// Used to make sure that no control characters are entered, which would break the editor.
  bool _isPrintable(int charCode) {
    return charCode >= 32 && charCode <= 126;
  }

  /// # `bool` _hexView(Key key)
  /// ## Handle key presses in the hex view.
  bool _hexView(Key key) {
    bool quit = false;
    if (!key.isControl) {
      switch (key.char) {
        case 'e':
          currentView = Views.dataFooter;
          currentFormat = Formats.u8;
          _currentValue = null;
          render();
          break;
        case 'a':
          currentView = Views.jumpToAddress;
          render();
          break;
      }
      return quit;
    }
    switch (key.controlChar) {
      case ControlCharacter.arrowUp:
        if (!(address - 0x10 < 0)) {
          address -= 0x10;
          render();
        }
        break;
      case ControlCharacter.arrowDown:
        if (!(address + 0x10 >= data.lengthInBytes)) {
          address += 0x10;
          render();
        }
        break;
      case ControlCharacter.arrowLeft:
        if (!(address - 0x01 < 0)) {
          address -= 0x01;
          render();
        }
        break;
      case ControlCharacter.arrowRight:
        if (!(address + 0x01 >= data.lengthInBytes)) {
          address += 0x01;
          render();
        }
        break;
      case ControlCharacter.ctrlQ:
        quit = true;
        break;
      case ControlCharacter.ctrlS:
        _primaryFile.save();
        if (_secondaryFile != null) {
          differences = _primaryFile.getDifferences(_secondaryFile!);
        }
        render();
        break;
      default:
        break;
    }
    if (quit) {
      Cli.clearTerminal();
      Cli.moveCursorToTopLeft();
    }
    return quit;
  }

  /// # `void` _dataFooterView(Key key)
  /// ## Handle key presses in the data footer view.
  void _dataFooterView(Key key) {
    if (!key.isControl) {
      _currentValue ??= "";
      _currentValue = _currentValue! + key.char;
      render();
    }
    switch (key.controlChar) {
      case ControlCharacter.ctrlQ:
        currentView = Views.byteViewer;
        _currentValue = null;
        render();
        break;
      case ControlCharacter.arrowLeft:
        if (_currentValue != null) {
          break;
        }
        int newIndex = currentFormat.index - 1;
        if (newIndex < 0) {
          break;
        }
        currentFormat = Formats.values[newIndex];
        render();
        break;
      case ControlCharacter.arrowRight:
        if (_currentValue != null) {
          break;
        }
        int newIndex = currentFormat.index + 1;
        if (newIndex >= Formats.values.length) {
          break;
        }
        currentFormat = Formats.values[newIndex];
        render();
        break;
      case ControlCharacter.backspace:
        _backspaceCurrentValue();
        break;
      case ControlCharacter.enter:
        if (_currentValue != null && !error && _currentValue!.isNotEmpty) {
          try {
            switch (currentFormat) {
              case Formats.u8:
                data.setUint8(address, int.parse(_currentValue!));
                break;
              case Formats.u16:
                data.setUint16(address, int.parse(_currentValue!), dataEndian);
                break;
              case Formats.u32:
                data.setUint32(address, int.parse(_currentValue!), dataEndian);
                break;
              case Formats.u64:
                data.setUint64(address, int.parse(_currentValue!), dataEndian);
                break;
            }
            _currentValue = null;
            render();
          } catch (e) {
            Cli.clearTerminal();
            rethrow;
          }
          currentView = Views.byteViewer;
          render();
        }
      default:
        break;
    }
  }

  /// # `void` _jumpToAddressView(Key key)
  /// ## Handle key presses in the jump to address view.
  void _jumpToAddressView(Key key) {
    if (!key.isControl) {
      _currentValue ??= "";
      _currentValue = _currentValue! + key.char;
      render();
    }
    switch (key.controlChar) {
      case ControlCharacter.backspace:
        _backspaceCurrentValue();
      case ControlCharacter.ctrlQ:
        currentView = Views.byteViewer;
        _currentValue = null;
        render();
        break;
      case ControlCharacter.enter:
        if (_currentValue != null && !error && _currentValue!.isNotEmpty) {
          try {
            if (_currentValue!.startsWith("0x")) {
              _currentValue = _currentValue!.substring(2);
              address = int.parse(_currentValue!, radix: 16);
            } else {
              address = int.parse(_currentValue!);
            }
            _currentValue = null;
            currentView = Views.byteViewer;
            render();
          } catch (e) {
            Cli.clearTerminal();
            rethrow;
          }
        }
      default:
        break;
    }
  }

  /// # `void` _backspaceCurrentValue()
  /// ## Backspace the `_currentValue`.
  void _backspaceCurrentValue() {
    if (_currentValue != null && _currentValue!.isNotEmpty) {
      _currentValue = _currentValue!.substring(0, _currentValue!.length - 1);
      render();
    }
  }

  /// # `Future<ByteData>` interact()
  /// ## Call this to start the editor for interaction.
  Future<ByteData> interact() async {
    int lastHeight = 1;
    int lastWidth = 1;
    bool quit = false;
    Cli.hideCursor();
    keyboard.onKeyPress.listen((key) {
      switch (currentView) {
        case Views.byteViewer:
          quit = _hexView(key);
          break;
        case Views.dataFooter:
          _dataFooterView(key);
          break;
        case Views.jumpToAddress:
          _jumpToAddressView(key);
        default:
          break;
      }
    });
    while (!quit) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (lastHeight != Cli.windowHeight || lastWidth != Cli.windowWidth) {
        lastHeight = Cli.windowHeight;
        lastWidth = Cli.windowWidth;
        render();
      }
    }
    Cli.showCursor();
    keyboard.dispose();
    return data;
  }
}

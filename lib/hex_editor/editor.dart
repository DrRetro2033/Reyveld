import 'dart:typed_data';
import 'dart:async';

import 'package:chalkdart/chalkstrings.dart';
import 'package:dart_console/dart_console.dart';
import '../cli.dart';
import '../version_control/dossier.dart';
import '../widget_system.dart';

enum Views {
  jumpToAddress,
  byteViewer,
  dataFooter,
  changeLog,
}

enum Formats { u8, u16, u32, u64 }

class HexEditor {
  final Plasma _primaryFile;
  Plasma? _secondaryFile;
  DifferenceMap differences = DifferenceMap();
  final keyboard = KeyboardInput();
  Views currentView = Views.byteViewer;
  ByteData get data => _primaryFile.data;
  Endian dataEndian = Endian.little;
  int address = 0;
  Formats currentFormat = Formats.u8;
  String? _currentValue;
  bool error = false;
  final List<int> byteColor = [255, 255, 255];
  final List<int> byte16Color = [140, 140, 140];
  final List<int> byte32Color = [100, 100, 100];
  final List<int> byte64Color = [60, 60, 60];

  HexEditor(this._primaryFile) {
    if (_primaryFile.isTracked()) {
      _secondaryFile = _primaryFile.findOlderVersion();
      differences = _primaryFile.getDifferences(_secondaryFile!);
    }
  }

  String getByteAt(int address) {
    return data.getUint8(address).toRadixString(16).padLeft(2, "0");
  }

  bool isValidAddress(int address) {
    return address >= 0 && address < data.lengthInBytes;
  }

  void render() {
    final header = Header(getHeader());
    final footer = Footer(getFooter());
    final body = TextWidget(getBody());

    final rootWidget = Column([
      header,
      body,
      footer,
    ]);

    WidgetSystem(rootWidget).render();
  }

  String getHeader() {
    String header = "";
    header += _primaryFile.getFilename().italic;
    if (_primaryFile.isTracked()) {
      header += " (Tracked)";
    }
    if (currentView == Views.byteViewer) {
      header += " - Ctrl+Q to quit. Ctrl+S to save.";
    } else if (currentView == Views.dataFooter) {
      header +=
          " - Ctrl+Q to return without applying changes. Press Enter to apply.";
    }
    return header;
  }

  String getFooter() {
    String footer = "";
    footer += "A".underline.bold;
    footer += "ddress: ";
    if (currentView == Views.jumpToAddress) {
      if (_currentValue != null) {
        int? x;
        if (_currentValue!.startsWith("0x")) {
          x = int.tryParse(_currentValue!.substring(2), radix: 16);
        } else {
          x = int.tryParse(_currentValue!);
        }

        if (x != null && x >= 0 && x < data.lengthInBytes) {
          footer += _currentValue!.bgBrightMagenta.black;
        } else {
          footer += _currentValue!.bgBrightRed.black;
          error = true;
        }
      } else {
        footer += "0x${address.toRadixString(16)}".bgBrightMagenta.black;
      }
    } else {
      footer += "0x${address.toRadixString(16)}";
    }
    footer += " | Line: ${getLineAddress()} ";
    footer += getValues(address);
    return footer;
  }

  int getLineAddress() {
    return ((address) >> 1 << 1) ~/ 16;
  }

  int getFileSizeInLines() {
    return (((data.lengthInBytes) >> 1 << 1) / 16).ceil();
  }

  String getValues(int byteAddress) {
    StringBuffer values = StringBuffer();
    for (Formats format in Formats.values) {
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
      values.write("\n");
      values.write("Ctrl+".underline.bold);
      values.write("E".underline.bold);
      values.write("ndian: ${dataEndian == Endian.little ? "Little" : "Big"}");
    }
    return values.toString();
  }

  String getBody() {
    final full = StringBuffer();
    final body = StringBuffer();
    int usableRows = Cli.windowHeight - 8;
    int startLine = 0;
    int endLine = (getFileSizeInLines());
    if (usableRows < getFileSizeInLines()) {
      int linesAboveBelow = usableRows ~/ 2;
      startLine = getLineAddress() - linesAboveBelow;
      endLine = getLineAddress() + linesAboveBelow;

      if (startLine < 0) {
        endLine += startLine.abs();
        startLine = 0;
      }
      if (endLine > getFileSizeInLines()) {
        startLine -= endLine - getFileSizeInLines();
        endLine = getFileSizeInLines();
      }
    }

    full.write("\t\t00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f\n"
        .padLeft(8, " "));
    for (int x = startLine * 16;
        x < data.lengthInBytes && x < endLine * 16;
        x += 16) {
      if (usableRows <= 0) {
        break;
      }
      final line = StringBuffer("");
      line.write("${x.toRadixString(16).padLeft(8, "0")}\t");
      for (int leftHalf = 0; leftHalf < 8; leftHalf++) {
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
      for (int rightHalf = 8; rightHalf < 16; rightHalf++) {
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
      usableRows--;
    }
    if (startLine > 0) {
      full.write("\t".padLeft(16, " "));
      full.write("───────────────────────^───────────────────────\n");
    } else {
      full.write("\n");
    }
    full.write(body.toString());
    if (endLine < getFileSizeInLines()) {
      full.write("\t".padLeft(16, " "));
      full.write("───────────────────────v───────────────────────\n");
    } else {
      full.write("\n");
    }
    return full.toString();
  }

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
    } else if (differences.isModified(byteAddress)) {
      value = value.brightCyan;
    }
    return value;
  }

  bool _isPrintable(int charCode) {
    return charCode >= 32 && charCode <= 126;
  }

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
      case ControlCharacter.ctrlE:
        dataEndian = dataEndian == Endian.little ? Endian.big : Endian.little;
        render();
      case ControlCharacter.pageUp:
        address = 0;
        render();
      case ControlCharacter.pageDown:
        address = data.lengthInBytes - 1;
        render();
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

  void _backspaceCurrentValue() {
    if (_currentValue != null && _currentValue!.isNotEmpty) {
      _currentValue = _currentValue!.substring(0, _currentValue!.length - 1);
      render();
    }
  }

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

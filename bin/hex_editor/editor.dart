import 'dart:io';
import 'dart:typed_data';

import 'package:chalkdart/chalkstrings.dart';
import 'package:dart_console/dart_console.dart';
import 'package:interact/src/framework/framework.dart';
import '../cli.dart';

class HexEditor extends Component<ByteData> {
  final File _file;
  final console = Console();

  HexEditor(this._file) {
    data = _file.readAsBytesSync().buffer.asByteData();
  }
  ByteData? data;
  @override
  HexEditorState createState() => HexEditorState();
}

class HexEditorState extends State<HexEditor> {
  static const int _minDataHeight = 15;
  int address = 0;
  final List<int> byteColor = [255, 255, 255];
  final List<int> byte16Color = [140, 140, 140];
  final List<int> byte32Color = [100, 100, 100];
  final List<int> byte64Color = [80, 80, 80];

  String getByteAt(int address) {
    return component.data!.getUint8(address).toRadixString(16).padLeft(2, "0");
  }

  bool isValidAddress(int address) {
    return address >= 0 && address < component.data!.lengthInBytes;
  }

  @override
  void init() {
    super.init();
    context.hideCursor();
  }

  @override
  void dispose() {
    context.showCursor();
    super.dispose();
  }

  @override
  void render() {
    component.console.resetCursorPosition();
    Cli.clearTerminal();
    // component.console.clearScreen();
    int usableRows = component.console.windowHeight - _minDataHeight;
    int linesAboveBelow = usableRows ~/ 2;
    int startLine = (address ~/ 16) - linesAboveBelow;
    int endLine = (address ~/ 16) + linesAboveBelow;

    // Adjust start and end to ensure full screen is used
    if (startLine < 0) {
      startLine = 0;
      endLine = startLine + usableRows;
    } else if (endLine >= ((component.data!.lengthInBytes / 16).ceil())) {
      endLine = (component.data!.lengthInBytes / 16).ceil();
      startLine = endLine - usableRows;
      if (startLine < 0) startLine = 0; // Ensure we don't go below zero
    }

    final editor = StringBuffer();
    context.write("\t\t00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f\n"
        .padLeft(8, " ")); // Address Headers
    final body = StringBuffer();
    for (int x = startLine * 16 < 0 ? 0 : startLine * 16;
        x < component.data!.lengthInBytes && x < endLine * 16;
        x += 16) {
      final line = StringBuffer("");
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
          final char = component.data!.getUint8(x + j);
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
      context.write("\t".padLeft(16, " "));
      context.write("───────────────────────^───────────────────────\n");
    } else {
      context.write("\n");
    }
    context.write(body.toString());
    if (endLine != ((component.data!.lengthInBytes / 16).ceil())) {
      //Notifies user that there is more data below
      context.write("\t".padLeft(16, " "));
      context.write("───────────────────────v───────────────────────\n");
    } else {
      context.write("\n");
    }
    editor.writeln();
    editor.writeln("Address: 0x${address.toRadixString(16)} ");
    editor.write("u8:".bgRgb(byteColor[0], byteColor[1], byteColor[2]).black);
    editor.writeln("${component.data!.getUint8(address)}");
    context.write(editor.toString());
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
    return value;
  }

  bool _isPrintable(int charCode) {
    return charCode >= 32 && charCode <= 126;
  }

  @override
  ByteData interact() {
    while (true) {
      final key = context.readKey();
      bool quit = false;
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          setState(() {
            if (!(address - 0x10 < 0)) {
              address -= 0x10;
            }
          });
          break;
        case ControlCharacter.arrowDown:
          setState(() {
            if (!(address + 0x10 >= component.data!.lengthInBytes)) {
              address += 0x10;
            }
          });
          break;
        case ControlCharacter.arrowLeft:
          setState(() {
            if (!(address - 0x01 < 0)) {
              address -= 0x01;
            }
          });
          break;
        case ControlCharacter.arrowRight:
          setState(() {
            if (!(address + 0x01 >= component.data!.lengthInBytes)) {
              address += 0x01;
            }
          });
          break;
        case ControlCharacter.ctrlQ:
          quit = true;
          break;
        default:
          break;
      }
      if (quit) {
        return component.data!;
      }
    }
  }
}

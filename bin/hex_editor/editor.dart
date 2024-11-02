import 'dart:io';
import 'dart:typed_data';
import 'package:chalkdart/chalkstrings.dart';
import 'package:dart_console/dart_console.dart';
import 'package:interact/src/framework/framework.dart';

class HexEditor extends Component<ByteData> {
  final File _file;
  final console = Console();
  String? lastFrame;

  HexEditor(this._file) {
    data = _file.readAsBytesSync().buffer.asByteData();
  }
  ByteData? data;
  @override
  HexEditorState createState() => HexEditorState();
}

class HexEditorState extends State<HexEditor> {
  int address = 0;
  List<int> byteColor = [255, 255, 255];
  List<int> byte16Color = [140, 140, 140];
  List<int> byte32Color = [100, 100, 100];
  List<int> byte64Color = [80, 80, 80];

  String getByteAt(int address) {
    return component.data!.getUint8(address).toRadixString(16).padLeft(2, "0");
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
    component.console.clearScreen();
    final editor = StringBuffer();

    for (int i = 0; i < component.data!.lengthInBytes; i++) {
      if ((i) % 16 == 0) {
        editor.write("\n");
      } else if (i % 8 == 0) {
        editor.write(" ");
      } else {
        editor.write("│");
      }
      String value = getByteAt(i);
      if (i == address) {
        value =
            getByteAt(i).bgRgb(byteColor[0], byteColor[1], byteColor[2]).black;
      } else if (i == address + 1) {
        value =
            value.bgRgb(byte16Color[0], byte16Color[1], byte16Color[2]).black;
      } else if (i >= address + 2 && i <= address + 3) {
        value =
            value.bgRgb(byte32Color[0], byte32Color[1], byte32Color[2]).black;
      } else if (i >= address + 4 && i <= address + 7) {
        value =
            value.bgRgb(byte64Color[0], byte64Color[1], byte64Color[2]).black;
      }
      editor.write(value);
    }
    editor.writeln();
    editor.writeln("Address: 0x${address.toRadixString(16)} ");
    editor.write("u8:".bgRgb(byteColor[0], byteColor[1], byteColor[2]).black);
    editor.writeln("${component.data!.getUint8(address)}");
    if (address + 1 < component.data!.lengthInBytes) {
      editor.writeln("Little Endian:");
    }
    if (address + 1 < component.data!.lengthInBytes) {
      editor.write(
          "\tu16:".bgRgb(byte16Color[0], byte16Color[1], byte16Color[2]).black);
      editor.write("${component.data!.getUint16(address, Endian.little)}\n");
    }
    if (address + 3 < component.data!.lengthInBytes) {
      editor.write(
          "\tu32:".bgRgb(byte32Color[0], byte32Color[1], byte32Color[2]).black);
      editor.write("${component.data!.getUint32(address, Endian.little)}\n");
    }
    if (address + 7 < component.data!.lengthInBytes) {
      editor.write(
          "\tu64:".bgRgb(byte64Color[0], byte64Color[1], byte64Color[2]).black);
      editor.write("${component.data!.getUint64(address, Endian.little)}\n");
    }
    if (address + 1 < component.data!.lengthInBytes) {
      editor.writeln("Big Endian:");
    }
    if (address + 1 < component.data!.lengthInBytes) {
      editor.write(
          "\tu16:".bgRgb(byte16Color[0], byte16Color[1], byte16Color[2]).black);
      editor.write("${component.data!.getUint16(address, Endian.big)}\n");
    }
    if (address + 3 < component.data!.lengthInBytes) {
      editor.write(
          "\tu32:".bgRgb(byte32Color[0], byte32Color[1], byte32Color[2]).black);
      editor.write("${component.data!.getUint32(address, Endian.big)}\n");
    }
    if (address + 7 < component.data!.lengthInBytes) {
      editor.write(
          "\tu64:".bgRgb(byte64Color[0], byte64Color[1], byte64Color[2]).black);
      editor.write("${component.data!.getUint64(address, Endian.big)}\n");
    }
    context.write(editor.toString());
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

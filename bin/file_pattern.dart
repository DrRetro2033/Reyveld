import "package:cli_spin/cli_spin.dart";
import "package:yaml/yaml.dart";
import "extensions.dart";
import 'main.dart';
import "dart:io";
import "dart:typed_data";

/// ### Create Data Structures in Minutes
/// Arceus uses the YAML format to make reading and writing to save games easier and more efficient.
///
/// #### YAML Formatting
/// For basic bytes, just give create a key with the size and the address.
/// ```yaml
/// encryption_constant:
///   size: u32 # You can also use u16, u8 as well.
///   address: 0x00
/// ```
/// If the value you want is smaller than a byte, you can use a bitfield instead.
/// ```yaml
/// IVSpan:
///   address: 0x8C
///   bits: #  Multiple bits are allowed in any number of bytes.
///     garbage: pad 1 #Padding can be used to align bits.
///     junk: pad 2 #Just add "pad" before the size of the padding.
///     trash: pad 1
///     iv_hp: 5 # Specify the size of each value.
///     iv_atk: 5
///     iv_def: 5
///     iv_spe: 5
///     iv_spa: 5
///     iv_spd: 5
///     is_egg: 1 # You can even have a boolean in a bitfield!
///     is_nicknamed: 1
/// ```
class FilePattern {
  static final Map<String, dynamic> _parsedPatterns =
      {}; // Patterns already parsed by Arceus.
  YamlMap? _currentPattern; // The current pattern being parsed.
  FilePattern(String path) {
    path = path.fixPath();
    _currentPattern = _getPattern(path);
  }

  Map<String, dynamic> read(Uint8List data) {
    return _read(data.buffer.asByteData(), _currentPattern!, 0);
  }

  Map<String, dynamic> _read(ByteData data, YamlMap pattern, int address) {
    final spinner = CliSpin(
            text: "Parsing ${_currentPattern!["path"]}",
            spinner: CliSpinners.star)
        .start();
    Map<String, dynamic> parsedData = {};

    // Imports
    if (pattern.containsKey("imports")) {
      for (YamlMap import in pattern["imports"]) {
        parsedData.addAll(_read(
            data, _getPattern(import["path"]), import["address"] + address));
      }
    }

    // Everything else
    for (String key in pattern.keys) {
      dynamic item = pattern[key];
      // print("key: $key, item: $item");
      if (item is YamlMap) {
        if (PatternVariable.tryParse(item)) {
          /// Variables.
          print("Parsing variable: $key");
          parsedData[key] =
              PatternVariable.fromYaml(item).getData(data, address);
        } else if (PatternArray.tryParse(item)) {
          /// Arrays.
          print("Parsing array: $key");
          parsedData[key] = PatternArray.fromYaml(item).getData(data, address);
        } else if (PatternBitfield.tryParse(item)) {
          /// Bitfields.
          print("Parsing bitfield: $key");
          parsedData
              .addAll(PatternBitfield.fromYaml(item).getData(data, address));
        } else {
          throw Exception("Unknown item type defined in pattern. $key");
        }
      }
    }

    spinner.success("Parsed successfully.");
    return parsedData;
  }

  /// # `YamlMap` _getPattern(`String path`)
  /// ## Returns the parsed pattern.
  /// This is internal and should not be called directly.
  YamlMap _getPattern(String path) {
    if (!(_parsedPatterns.containsKey(path))) {
      if (path.startsWith("./")) {
        path = currentPath + path.substring(1);
      }
      File file = File(path);
      if (file.existsSync()) {
        _parsedPatterns[path] = loadYaml(file.readAsStringSync());
      } else {
        throw Exception("Pattern $path not found.");
      }
    }
    return _parsedPatterns[path];
  }
}

abstract class PatternObject {
  int address;
  dynamic size;
  int get byteSize => (size == null) ? 0 : int.parse(size!);
  PatternObject(this.address, {this.size});
  static bool tryParse(YamlMap item) {
    return false;
  }

  dynamic getData(ByteData data, int offsetAddress) {
    return null;
  }
}

class PatternVariable extends PatternObject {
  PatternVariable(super.address, {super.size});

  @override
  int get byteSize => _byteSize();

  factory PatternVariable.fromYaml(YamlMap item) {
    return PatternVariable(item["address"] as int,
        size: item["size"] as String);
  }

  int _byteSize() {
    switch (size) {
      case "u8":
        return 1;
      case "u16":
        return 2;
      case "u32":
        return 4;
    }
    throw Exception("Unsupported size: $size.");
  }

  static bool tryParse(YamlMap item) {
    if (!item.containsKey("address")) {
      return false;
    }

    if (!item.containsKey("size")) {
      return false;
    }

    if (item["size"] is! String) {
      return false;
    }

    if (["u8", "u16", "u32"].any((element) => element == item["size"])) {
      return true;
    }
    return false;
  }

  @override
  dynamic getData(ByteData data, int offsetAddress) {
    switch (size) {
      case "u8":
        return data.getUint8(address + offsetAddress);
      case "u16":
        return data.getUint16(address + offsetAddress);
      case "u32":
        return data.getUint32(address + offsetAddress);
    }
    throw Exception("Unsupported size: $size.");
  }
}

class PatternArray extends PatternObject {
  bool? endAtZero;
  PatternArray(super.address, {super.size, this.endAtZero});

  factory PatternArray.fromYaml(YamlMap item) {
    return PatternArray(
      item["address"] as int,
      size: item["size"] as String,
      endAtZero: item["endAtZero"] as bool?,
    );
  }

  static bool tryParse(YamlMap item) {
    if (!item.containsKey("address")) {
      print("No Address.");
      return false;
    }

    if (!item.containsKey("size")) {
      print("No Size.");
      return false;
    }

    if (item["size"] is! String) {
      print("Size is not a string.");
      return false;
    }
    if (["char16"].any((element) =>
        (item["size"] as String).startsWith("$element[") &&
        (item["size"] as String).endsWith("]"))) {
      int? hexSize = _getSizeOfCharArray(item["size"] as String);
      if (hexSize == null) {
        print("Invalid size.");
        return false;
      }
      return true;
    }
    return false;
  }

  static int? _getSizeOfCharArray(String size) {
    String x = ((size.split("[")[1]).split("]")[0]);
    if (x.startsWith("0x")) {
      x = x.substring(2);
    }
    int? hexSize = int.tryParse(x, radix: 16);
    return hexSize;
  }

  @override
  dynamic getData(ByteData data, int offsetAddress) {
    String string = "";
    for (int i = 0; i < (_getSizeOfCharArray(size)! * 2); i += 2) {
      if (endAtZero! &&
          string.isNotEmpty &&
          data.getUint16(offsetAddress + address + i, Endian.little) == 0) {
        break;
      }
      string += String.fromCharCode(
          data.getUint16(offsetAddress + address + i, Endian.little));
    }
    return string;
  }
}

class PatternBitfield extends PatternObject {
  YamlMap? bitfield;
  PatternBitfield(super.address, this.bitfield, {super.size});

  factory PatternBitfield.fromYaml(YamlMap item) {
    return PatternBitfield(item["address"] as int, item["bits"],
        size: _getSizeOfBitField(item["bits"]));
  }

  static bool tryParse(YamlMap item) {
    if (!item.containsKey("address")) {
      return false;
    }

    if (!item.containsKey("bits")) {
      return false;
    }

    if (item["bits"] is! YamlMap) {
      return false;
    }
    return true;
  }

  @override
  dynamic getData(ByteData data, int offsetAddress) {
    Map<String, dynamic> parsedData = {};
    // Bitfields
    // print("$key:${_getSizeOfBitField(item["bits"])}");
    BigInt combinedNumber = BigInt.zero; // The total binary value.
    for (int i = size - 1; i >= size; i--) {
      // Starting from the end of the bitfield, each byte is bitshifted into the combined number until the start of the byte is reached.
      combinedNumber = (combinedNumber << 8) |
          BigInt.from(data.getUint8(address + offsetAddress + i));
    }
    // print(combinedNumber.toRadixString(2).length);
    int offset = 0;
    for (String key in bitfield!.keys) {
      int size = 0; // Size of the range of bits.
      bool isPadding = false; // Whether the range of bits is padding.
      // If it is padding, it just adds the preceding number in the pad command and skips the if else chain below.
      if (bitfield?[key] is int) {
        // Is the key-value pair a number?
        size = bitfield?[key] as int;
      } else if (bitfield?[key] is String &&
          (bitfield?[key] as String).startsWith("pad")) {
        // Is the key-value pair a pad command?
        size = int.parse((bitfield?[key] as String).substring(3).trim());
        isPadding = true;
      } else {
        throw Exception(
            "Unsupported bitfield type: ${bitfield?[key]}. Not continuing as every subsequent value will be out of alignment.");
      }

      // This is where the data is fetched from the bitfield.
      if (!isPadding) {
        parsedData[key] = _getValueInBitfield(
            combinedNumber, offset, size); // The value of the bit range.
        // print(((BigInt.one << size) - BigInt.one).toRadixString(2));
        // print("$key: ${(parsedData[key] as int).toRadixString(2)}");
      }

      // Move the offset by the size of the range of bits.
      offset += size;
    }
    return parsedData;
  }

  /// # `int` _getSizeOfBitField(`YamlMap item`)
  /// ## Returns the size of the bitfield in bytes.
  static int _getSizeOfBitField(YamlMap item) {
    int size = 0;
    for (String key in item.keys) {
      if (item[key] is int) {
        size += item[key] as int;
      } else if (item[key] is String &&
          (item[key] as String).startsWith("pad")) {
        size += int.parse((item[key] as String).substring(3));
      }
    }
    return (size / 8).ceil();
  }

  /// # `dynamic` _getValueInBitfield(`BigInt combinedNumber`, `int offset`, `int size`)
  /// ## Returns the value of the bitfield in the combined number.
  /// TODO: Add support for signed numbers.
  dynamic _getValueInBitfield(BigInt combinedNumber, int offset, int size) {
    BigInt value =
        ((combinedNumber >> offset) & ((BigInt.one << size) - BigInt.one));
    if (size == 1) {
      return value == BigInt.zero ? false : true;
    } else if (size > 1 && size <= 64) {
      return value.toInt();
    } else {
      throw Exception("Unsupported bitfield size: $size.");
    }
  }
}

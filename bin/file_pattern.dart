import "package:yaml/yaml.dart";
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
  YamlMap? _currentPattern;
  FilePattern(String extension) {
    _currentPattern = _getPattern("files/$extension.yaml");
  }

  Map<String, dynamic> read(File file) {
    Uint8List data = file.readAsBytesSync();
    return _read(data.buffer.asByteData(), _currentPattern!, 0);
  }

  Map<String, dynamic> _read(ByteData data, YamlMap pattern, int address) {
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
      if (item is YamlMap) {
        if (!item.containsKey("address")) {
          continue;
        }

        if (item.containsKey("size")) {
          if (item["size"] is! String) {
            throw Exception("Size must be a valid format.");
          }

          if ((item["size"] as String).contains("char16")) {
            String string = "";
            for (int i = 0;
                i < (_getSizeOfCharArray(item["size"]) * 2);
                i += 2) {
              string += String.fromCharCode(
                  data.getUint16(item["address"] + address + i, Endian.little));
            }
            parsedData[key] = string;
          }

          switch (item["size"]) {
            // Numbers
            case "u8":
              parsedData[key] = data.getUint8(item["address"] + address);
              break;
            case "u16":
              parsedData[key] =
                  data.getUint16(item["address"] + address, Endian.little);
              break;
            case "u32":
              parsedData[key] =
                  data.getUint32(item["address"] + address, Endian.little);
              break;
          }
        } else if (item.containsKey("bits") && item["bits"] is YamlMap) {
          // Bitfields
          // print("$key:${_getSizeOfBitField(item["bits"])}");
          BigInt combinedNumber = BigInt.zero; // The total binary value.
          for (int i = _getSizeOfBitField(item["bits"]) - 1; i >= 0; i--) {
            // Starting from the end of the bitfield, each byte is bitshifted into the combined number until the start of the byte is reached.
            combinedNumber = (combinedNumber << 8) |
                BigInt.from(data.getUint8(item["address"] + address + i));
          }
          // print(combinedNumber.toRadixString(2).length);
          int offset = 0; // Offset in the binary number.
          YamlMap bitfield =
              item["bits"]; // The names and sizes of each range of bits.
          for (String key in bitfield.keys) {
            int size = 0; // Size of the range of bits.
            bool isPadding = false; // Whether the range of bits is padding.
            // If it is padding, it just adds the preceding number in the pad command and skips the if else chain below.
            if (bitfield[key] is int) {
              // Is the key-value pair a number?
              size = bitfield[key] as int;
            } else if (bitfield[key] is String &&
                (bitfield[key] as String).startsWith("pad")) {
              // Is the key-value pair a pad command?
              size = int.parse((bitfield[key] as String).substring(3).trim());
              isPadding = true;
            } else {
              throw Exception(
                  "Unsupported bitfield type: ${bitfield[key]}. Not continuing as every subsequent value will be out of alignment.");
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
        }
      }
    }

    return parsedData;
  }

  /// # `int` _getSizeOfCharArray(`String sizeString`)
  /// ## Returns the size of the char array in bytes.
  /// The string you should pass must end with a hex or dec number in square brackets. e.g. `char16[16]` or `char16[0x10]`.
  int _getSizeOfCharArray(String sizeString) {
    String x = sizeString.split("[")[1]; // Decides the size of the char array.
    //TODO: Replace with a regular expression for typed arrays, not just char16.
    x = x.split("]")[0];
    if (x.startsWith("0x")) {
      return int.parse(x.substring(2), radix: 16);
    }
    return int.parse(x);
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

  /// # `int` _getSizeOfBitField(`YamlMap item`)
  /// ## Returns the size of the bitfield in bytes.
  int _getSizeOfBitField(YamlMap item) {
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

  /// # `YamlMap` _getPattern(`String path`)
  /// ## Returns the parsed pattern.
  /// This is internal and should not be called directly.
  YamlMap _getPattern(String path) {
    if (!(_parsedPatterns.containsKey(path))) {
      File file = File("${Directory.current.path}/assets/patterns/$path");
      if (file.existsSync()) {
        _parsedPatterns[path] = loadYaml(file.readAsStringSync());
      } else {
        throw Exception("Pattern $path not found.");
      }
    }
    return _parsedPatterns[path];
  }
}

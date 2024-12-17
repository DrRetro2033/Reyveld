import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:yaml/yaml.dart';

import 'scripting/addon.dart';

/// # `extension` Compression
/// ## Extension for the `String` class.
/// Used to compress and decompress strings.
extension Compression on String {
  /// # `String` fixPath()
  /// ## Fixes the path by replacing backslashes with forward slashes.
  /// This is used to make the path compatible with the operating system.
  String fixPath() {
    String path = replaceAll("\"", "");
    return path.replaceAll("\\", "/");
  }

  /// # `String` makeRelPath(`String` relativeTo)
  /// ## Makes the path relative to the given path.
  /// This is used to make the path relative to the given path.
  String makeRelPath(String relativeTo) {
    return replaceFirst("$relativeTo\\", "").fixPath();
  }

  /// # `String` fromHexToCodes()
  /// ## Converts a hex string to character codes.
  /// This is used to convert a readable hex string to a character codes, to save space in files.
  String fromHexToCodes() {
    if (length % 2 == 0) {
      String finalString = "";
      for (int i = 0; i < length; i += 2) {
        finalString +=
            String.fromCharCode(int.parse(substring(i, i + 2), radix: 16));
      }
      return finalString;
    }
    throw Exception("Invalid hex string.");
  }

  /// # `String` fromCodesToHex()
  /// ## Converts character codes to a hex string.
  /// This is used to convert character codes to a readable hex string, to decrypt Strings from `fromHexToCodes()`.
  String fromCodesToHex() {
    String finalString = "";
    for (int i = 0; i < length; ++i) {
      finalString += codeUnitAt(i).toRadixString(16).padLeft(2, "0");
    }
    return finalString;
  }

  /// # `String` getFilename()
  /// ## Returns the filename of the string.
  /// The filename will be the same for both internal and external paths.
  String getFilename({bool withExtension = true}) {
    String path = fixPath();
    if (withExtension) {
      return path.split("/").last;
    } else {
      return path.split("/").last.split(".").first;
    }
  }

  /// # `String` getExtension()
  /// ## Returns the extension of the string.
  /// The extension will be the same for both internal and external paths.
  String getExtension() {
    String path = fixPath();
    return path.split(".").last;
  }
}

extension CNativeString on String {
  Pointer<Char> toCharPointer() {
    var nativeUtf8 = toNativeUtf8();
    var pointer = nativeUtf8.cast<Char>();
    malloc.free(nativeUtf8);
    return pointer;
  }
}

extension NativeString on Pointer<Char> {
  String toDartString() {
    return cast<Utf8>().toDartString();
  }
}

/// # `extension` DifferenceChecking
/// ## Extension for the `ByteData` class.
/// Used to check if two `ByteData` objects are different.
extension DifferenceChecking on ByteData {
  bool checkForDifferences(ByteData other) {
    if (other.lengthInBytes != lengthInBytes) {
      return true;
    }
    for (int i = 0; i < lengthInBytes; i++) {
      if (getUint8(i) != other.getUint8(i)) {
        return true;
      }
    }
    return false;
  }
}

extension AddonList on List<Addon> {
  List<Addon> filterByAssociatedFile(String associatedFile) {
    return where((addon) {
      if (addon.featureSet != FeatureSets.pattern) return false;
      return (addon.getMetadata()["associated-files"] as YamlList).any(
          (extension) =>
              (extension as String).endsWith(associatedFile.getExtension()));
    }).toList();
  }
}

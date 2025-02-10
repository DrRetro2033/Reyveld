import 'dart:ffi';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ffi/ffi.dart';

// import 'package:arceus/scripting/addon.dart';

/// # `extension` Compression
/// ## Extension for the `String` class.
/// Used to compress and decompress strings.
extension Pathing on String {
  /// # `String` fixPath()
  /// ## Fixes the path by replacing windows formatting with an absolute path and universal format.
  /// This will also replace environment variables with their values.
  String fixPath() {
    String path = replaceAll("\"", "");
    path = path.replaceAll("\\", "/");
    if (Platform.isWindows) {
      /// Replace environment variables to absolute paths on Windows
      RegExp envVar = RegExp(r"(?:%(\w*)%)");
      for (RegExpMatch match in envVar.allMatches(path)) {
        path = path.replaceFirst(
            match.group(0)!, Platform.environment[match.group(1)!]!.fixPath());
      }
    }
    if (path.startsWith("/")) path = path.substring(1);
    return path;
  }

  String relativeTo(String relativeTo) {
    final formattedPath = fixPath();
    final formattedRelativeTo = relativeTo.fixPath();
    return formattedPath.replaceFirst(formattedRelativeTo, "").fixPath();
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
    return path.split(".").sublist(1).join(".");
  }
}

extension CNativeString on String {
  Pointer<Char> toCharPointer() {
    var nativeUtf8 = toNativeUtf8();
    var pointer = nativeUtf8.cast<Char>();
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
extension DifferenceChecking on List<int> {
  bool equals(List<int> other) {
    if (other.length != length) {
      return false;
    }
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }
}

extension CommandGlobalCommands on Command {
  String findOption<T>(String name) {
    String? value = argResults!.option(name) ?? globalResults!.option(name);
    if (value == null) {
      throw ArgumentError.notNull(name);
    }
    return value;
  }
}

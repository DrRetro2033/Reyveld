import 'dart:typed_data';

extension Compression on String {
  String fixPath() {
    String path = replaceAll("\"", "");
    return path.replaceAll("\\", "/");
  }

  String makeRelPath(String relativeTo) {
    return replaceFirst("$relativeTo\\", "").fixPath();
  }

  /// # `String` fromHexToCodes(`String` path)
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

  /// # `String` fromCodesToHex(`String` path)
  /// ## Converts character codes to a hex string.
  /// This is used to convert character codes to a readable hex string, to decrypt Strings from `fromHexToCodes()`.
  String fromCodesToHex() {
    String finalString = "";
    for (int i = 0; i < length; ++i) {
      finalString += codeUnitAt(i).toRadixString(16);
    }
    return finalString;
  }

  String getFilename() {
    String path = fixPath();
    return path.split("/").last;
  }
}

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

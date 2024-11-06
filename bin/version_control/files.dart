import 'dart:io';
import 'dart:typed_data';
import '../extensions.dart';
import 'star.dart';

/// # `class` `BaseFile`
/// ## A base class for internal and external files.
/// Represents an internal file (i.e. inside a `.star` file) or an external file (i.e. inside the current directory).
sealed class BaseFile {
  String path;
  ByteData get data => ByteData(0);
  set data(ByteData newData) {
    throw UnimplementedError(
        "Not implemented. Please implement in a subclass.");
  }

  BaseFile(this.path);

  /// # `operator` `==`
  /// ## Checks to see if the file is different from another file.
  @override
  operator ==(Object other) {
    if (other is BaseFile) {
      data.checkForDifferences(other.data);
    }
    return false;
  }

  @override
  int get hashCode => data.hashCode;
}

/// # `class` `InternalFile` extends `BaseFile`
/// ## Represents an internal file (i.e. inside a `.star` file).
class InternalFile extends BaseFile {
  Star star;

  @override
  ByteData get data => _build();

  @override
  set data(ByteData newData) {
    throw Exception("You cannot set data for an internal file.");
  }

  InternalFile(this.star, super.path) {
    if (star.getArchive().findFile(path) == null) {
      throw Exception(
          "File not found: $path. Please check the path and star and try again.");
    }
  }

  ByteData _build() {
    Star? currentStar = star.getParentStar();
    Uint8List data = star.getArchive().findFile(path)?.content as Uint8List;
    while (currentStar != null) {
      Uint8List content =
          currentStar.getArchive().findFile(path)?.content as Uint8List;
      for (int x = 0; x < data.length; x++) {
        if (data[x] == 0) {
          data[x] = content[x];
        }
      }
      currentStar = currentStar.getParentStar();
    }
    return data.buffer.asByteData();
  }
}

/// # `class` ExternalFile extends `BaseFile`
/// ## Represents an external file (i.e. inside the current directory).
class ExternalFile extends BaseFile {
  ExternalFile(super.path);

  @override
  ByteData get data => File(path).readAsBytesSync().buffer.asByteData();

  @override
  set data(ByteData newData) {
    File(path).writeAsBytesSync(newData.buffer.asUint8List().toList());
  }
}

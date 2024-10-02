import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'star.dart';

/// # `mixin` `CheckForDifferencesInData`
/// ## A mixin to check for differences in data, for use in the `BaseFile` class.
mixin CheckForDifferencesInData {
  bool _check(Uint8List data1, Uint8List data2) {
    if (data1.length != data2.length) {
      return true;
    }
    for (int x = 0; x < data1.length; x++) {
      if (data1[x] != data2[x]) {
        return true;
      }
    }
    return false;
  }
}

/// # `class` `BaseFile`
/// ## A base class for internal and external files.
/// Represents an internal file (i.e. inside a `.star` file) or an external file (i.e. inside the current directory).
sealed class BaseFile with CheckForDifferencesInData {
  String path;
  Uint8List get data => Uint8List(0);
  set data(Uint8List newData) {
    throw UnimplementedError(
        "Not implemented. Please implement in a subclass.");
  }

  BaseFile(this.path);

  /// # `operator` `==`
  /// ## Checks to see if the file is different from another file.
  @override
  operator ==(Object other) {
    if (other is BaseFile) {
      return !_check(data, other.data);
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
  Uint8List get data => build();

  @override
  set data(Uint8List newData) {
    if (star.archive.findFile(path) != null) {
      throw Exception("You cannot set data for a existing file inside a star.");
    }
    star.archive.addFile(ArchiveFile(path, newData.length, newData));
  }

  InternalFile(this.star, super.path) {
    if (star.getArchive().findFile(path) == null) {
      throw Exception(
          "File not found: $path. Please check the path and star and try again.");
    }
  }

  Uint8List build() {
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
    return data;
  }
}

/// # `class` ExternalFile extends `BaseFile`
/// ## Represents an external file (i.e. inside the current directory).
class ExternalFile extends BaseFile {
  ExternalFile(super.path);

  @override
  Uint8List get data => File(path).readAsBytesSync();

  @override
  set data(Uint8List newData) {
    File(path).writeAsBytesSync(newData);
  }
}

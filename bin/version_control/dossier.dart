import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import 'star.dart';
import 'package:ansix/ansix.dart';
import 'package:cli_spin/cli_spin.dart';
import '../extensions.dart';
import '../arceus.dart';
import 'constellation.dart';

/// # `class` `Dossier`
/// ## A wrapper for the internal and external file systems.
/// Acts as a wrapper for the internal file system (i.e. Inside a `.star` file) and the external file system (i.e. Inside the current directory).
class Dossier {
  Star star; // The star used for the internal file system.
  // The following are used for the CLI:
  String addSymbol = "A".bold().green();
  String removeSymbol = "D".bold().red();
  String moveSymbol = "→".bold().aqua();
  String modifiedSymbol = "M".bold().yellow();

  Dossier(this.star);

  /// # `bool` checkForDifferences()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool checkForDifferences() {
    bool check =
        false; // The main check. If any of the preceding checks fail, this will be true, which means that there is a difference.

    // There are four checks that need to be done:
    // 1. Check for new files.
    // 2. Check for removed files.
    // 3. Check for moved files.
    // 4. Check for changed files.

    // Check for new files.
    var spinner = CliSpin(text: " Checking for new files...").start();
    List<String> newFiles = listAddedFiles();
    spinner.stop();
    // Check for removed files.
    spinner = CliSpin(text: " Checking for removed files...").start();
    List<String> removedFiles = listRemovedFiles();
    spinner.stop();

    // Check for moved files. Done after new and removed files, as they can be used here to make a cross reference.
    spinner = CliSpin(text: " Checking for moved files...").start();
    Map<String, String> movedFiles = listMovedFiles(newFiles, removedFiles);
    if (movedFiles.isNotEmpty) {
      check = true;
      spinner.stop();
      for (String file in movedFiles.keys) {
        print("  $file $moveSymbol ${movedFiles[file]}");
      }
    } else {
      spinner.success(" There are no moved files.");
    }

    if (newFiles.isNotEmpty) {
      check = true;
      spinner.fail(" New files found:");
      for (String file in newFiles) {
        if (movedFiles.containsValue(file)) {
          continue;
        }
        print("  $addSymbol $file");
      }
    } else {
      spinner.success(" There are no new files.");
    }

    if (removedFiles.isNotEmpty) {
      check = true;
      spinner.fail(" Removed files found:");
      for (String file in removedFiles) {
        if (movedFiles.containsKey(file)) {
          continue;
        }
        print("  $removeSymbol $file");
      }
    } else {
      spinner.success(" There are no removed files.");
    }

    // Check for changed files.
    spinner = CliSpin(text: " Checking for changed files...").start();
    List<String> changedFiles = listChangedFiles(removedFiles);
    if (changedFiles.isNotEmpty) {
      spinner.fail(" Changed files found:");
      check = true;
      for (String file in changedFiles) {
        print("  $modifiedSymbol $file");
      }
    } else {
      spinner.success(" There are no changed files.");
    }
    return check;
  }

  List<String> listAddedFiles() {
    List<String> newFiles = [];
    for (FileSystemEntity entity
        in star.constellation.directory.listSync(recursive: true)) {
      if (entity is File &&
          (!entity.path
              .fixPath()
              .contains(star.constellation.constellationPath))) {
        if (star.archive
                .findFile(entity.path.makeRelPath(star.constellation.path)) ==
            null) {
          newFiles.add(entity.path.makeRelPath(star.constellation.path));
        }
      }
    }
    return newFiles;
  }

  List<String> listRemovedFiles() {
    List<String> removedFiles = [];
    for (ArchiveFile file in star.archive.files) {
      if (file.isFile && file.name != "star") {
        if (!File("${star.constellation.path}/${file.name}").existsSync()) {
          removedFiles.add(file.name);
        }
      }
    }
    return removedFiles;
  }

  Map<String, String> listMovedFiles(
      List<String> newFiles, List<String> removedFiles) {
    Map<String, String> movedFiles = {};
    for (String file in removedFiles) {
      if (newFiles.any((e) => e.getFilename() == file.getFilename())) {
        Plasma externalFile = Plasma.fromFile(File(
            "${star.constellation.path}/${newFiles.firstWhere((e) => e.getFilename() == file.getFilename())}"));
        Plasma internalFile = Plasma.fromStar(star, file);
        if (externalFile == internalFile) {
          movedFiles[file] =
              newFiles.firstWhere((e) => e.getFilename() == file.getFilename());
        }
      }
    }
    return movedFiles;
  }

  List<String> listChangedFiles(List<String> removedFiles) {
    List<String> changedFiles = [];
    for (ArchiveFile file in star.archive.files) {
      if (file.isFile &&
          file.name != "star" &&
          !removedFiles.contains(file.name)) {
        Plasma internalFile = Plasma.fromStar(star, file.name);
        Plasma externalFile =
            Plasma.fromFile(File("${star.constellation.path}/${file.name}"));
        if (externalFile != internalFile) {
          changedFiles.add(file.name);
        }
      }
    }
    return changedFiles;
  }
}

/// # `enum` `Origin`
/// ## The origin of a `Plasma` object.
/// The origin can either internal (from a star) or external (from the current directory).
enum Origin { internal, external }

/// # `class` `Plasma`
/// ## A wrapper for the internal and external file systems.
/// Its called plasma because its one of the building blocks of a star.
class Plasma {
  Star? star;
  String? pathInStar;
  File? file;
  ByteData? _originalData;
  final ByteData data;
  final Origin origin;

  /// # `Plasma`(`ByteData` data)
  /// DO NOT CALL THIS DIRECTLY, USE ONE OF THE FACTORY METHODS ([Plasma.fromFile], [Plasma.fromStar]).
  Plasma(this.data, this.origin, {this.star, this.file, this.pathInStar}) {
    _originalData = Uint8List.fromList(data.buffer.asUint8List().toList())
        .buffer
        .asByteData();
  }

  @override
  // ignore: hash_and_equals
  operator ==(Object other) {
    if (other is Plasma) {
      return data.checkForDifferences(other.data);
    } else {
      return false;
    }
  }

  factory Plasma.fromFile(File file) {
    return Plasma(file.readAsBytesSync().buffer.asByteData(), Origin.external,
        file: file);
  }

  factory Plasma.fromStar(Star star, String pathInStar) {
    return Plasma(
        (star.archive.findFile(pathInStar)!.content as Uint8List)
            .buffer
            .asByteData(),
        Origin.internal,
        star: star,
        pathInStar: pathInStar);
  }

  void save() {
    if (origin == Origin.internal) {
      throw Exception(
          "Cannot save plasma from inside a star. Please try again with external file instead.");
    }
    file!.writeAsBytesSync(data.buffer.asUint8List());
    _originalData = Uint8List.fromList(data.buffer.asUint8List().toList())
        .buffer
        .asByteData();
  }

  String getFilename() {
    if (origin == Origin.internal) {
      return pathInStar!.getFilename();
    } else {
      return file!.path.getFilename();
    }
  }

  bool isTracked() {
    if (origin == Origin.internal) {
      return true;
    } else {
      return Arceus.doesConstellationExist(path: file!.path);
    }
  }

  Map<int, int> unsavedChanges() {
    Map<int, int> changes = {};
    for (int i = 0; i < data.lengthInBytes; ++i) {
      if (i >= _originalData!.lengthInBytes) {
        changes[i] = data.getUint8(i);
      } else if (data.getUint8(i) != _originalData!.getUint8(i)) {
        changes[i] = data.getUint8(i);
      }
    }
    return changes;
  }

  /// # `Map<int, int>` getDifferences(Plasma other)
  /// ## Compares the current plasma to another plasma.
  /// Returns a map of the differences between the two plasmas.
  /// The keys are the addresses of the differences, and the values are the values at those addresses in the current plasma.
  Map<int, int> getDifferences(Plasma other) {
    Map<int, int> differences = {};
    for (int i = 0; i < data.lengthInBytes; ++i) {
      if (i >= _originalData!.lengthInBytes) {
        differences[i] = data.getUint8(i);
      } else if (data.getUint8(i) != other.data.getUint8(i)) {
        differences[i] = data.getUint8(i);
      }
    }
    return differences;
  }

  Plasma? findOlderVersion() {
    if (origin == Origin.internal) {
      if (star!.parent != null) {
        return Plasma.fromStar(star!.parent!, pathInStar!);
      }
    } else if (origin == Origin.external) {
      if (Arceus.doesConstellationExist(path: file!.path)) {
        Constellation x = Arceus.getConstellationFromPath(file!.path)!;
        print(file!.path.fixPath().replaceFirst("${x.path}/", ""));
        return x.starmap
            ?.getMostRecentStar()
            .getPlasma(file!.path.fixPath().replaceFirst("${x.path}/", ""));
      }
    }
    return null;
  }
}

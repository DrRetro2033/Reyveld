import 'dart:io';
import 'dart:typed_data';

import 'package:arceus/scripting/addon.dart';
import 'package:arceus/scripting/feature_sets/feature_sets.dart';
import 'package:arceus/widget_system.dart';
import 'package:archive/archive_io.dart';
import 'package:yaml/yaml.dart';
import 'package:chalkdart/chalkstrings.dart';

import 'star.dart';
import 'package:cli_spin/cli_spin.dart';
import '../extensions.dart';
import '../arceus.dart';
import 'constellation.dart';

/// # `class` `Dossier`
/// ## A class that checks for differences between the star and the current directory.
class Dossier {
  /// # `Star` star
  /// ## The star that is being checked against the current directory.
  Star star;

  // The following are used for the CLI:
  final String _addSymbol = "A".bold.greenBright;
  final String _removeSymbol = "D".bold.redBright;
  final String _moveSymbol = "→".bold.cyanBright;
  final String _modifiedSymbol = "M".bold.yellowBright;

  Dossier(this.star);

  /// # `bool` checkForDifferences()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool checkForDifferences([bool silent = true]) {
    bool check =
        false; // The main check. If any of the preceding checks fail, this will be true, which means that there is a difference.

    // There are four checks that need to be done:
    // 1. Check for new files.
    // 2. Check for removed files.
    // 3. Check for moved files.
    // 4. Check for changed files.
    CliSpin? spinner;
    // Check for new files.
    if (!silent) {
      spinner = CliSpin(text: " Checking for new files...").start();
    }

    List<String> newFiles = _listAddedFiles();
    if (!silent) spinner!.stop();
    // Check for removed files.
    if (!silent) {
      spinner = CliSpin(text: " Checking for removed files...").start();
    }
    List<String> removedFiles = _listRemovedFiles();
    if (!silent) spinner!.stop();

    // Check for moved files. Done after new and removed files, as they can be used here to make a cross reference.
    if (!silent) {
      spinner = CliSpin(text: " Checking for moved files...").start();
    }
    Map<String, String> movedFiles = _listMovedFiles(newFiles, removedFiles);
    if (movedFiles.isNotEmpty) {
      check = true;
      spinner!.stop();
      for (String file in movedFiles.keys) {
        print("  $file $_moveSymbol ${movedFiles[file]}");
      }
    } else {
      spinner?.success(" There are no moved files.");
    }

    // Check for new files.
    if (newFiles.isNotEmpty) {
      check = true;
      spinner?.fail(" New files found:");
      for (String file in newFiles) {
        if (movedFiles.containsValue(file)) {
          continue;
        }
        print("  $_addSymbol $file");
      }
    } else {
      spinner?.success(" There are no new files.");
    }

    // Check for removed files.
    if (removedFiles.isNotEmpty) {
      check = true;
      spinner?.fail(" Removed files found:");
      for (String file in removedFiles) {
        if (movedFiles.containsKey(file)) {
          continue;
        }
        print("  $_removeSymbol $file");
      }
    } else {
      spinner?.success(" There are no removed files.");
    }

    // Check for changed files.
    if (!silent) {
      spinner = CliSpin(text: " Checking for changed files...").start();
    }
    List<String> changedFiles = _listChangedFiles(removedFiles);
    if (changedFiles.isNotEmpty) {
      spinner?.fail(" Changed files found:");
      check = true;
      for (String file in changedFiles) {
        print("  $_modifiedSymbol $file");
      }
    } else {
      spinner?.success(" There are no changed files.");
    }
    return check;
  }

  /// # `List<String>` listAddedFiles()
  /// ## Lists all files in the current directory that have been recently added.
  List<String> _listAddedFiles() {
    Archive archive = star.getArchive();
    List<String> newFiles = [];
    for (FileSystemEntity entity
        in star.constellation.directory.listSync(recursive: true)) {
      if (entity is File &&
          (!entity.path
              .fixPath()
              .contains(star.constellation.constellationPath))) {
        if (archive
                .findFile(entity.path.makeRelPath(star.constellation.path)) ==
            null) {
          newFiles.add(entity.path.makeRelPath(star.constellation.path));
        }
      }
    }
    archive.clearSync();
    return newFiles;
  }

  /// # `List<String>` listRemovedFiles()
  /// ## Lists all files in the current directory that have been recently removed.
  List<String> _listRemovedFiles() {
    Archive archive = star.getArchive();
    List<String> removedFiles = [];
    for (ArchiveFile file in archive.files) {
      if (file.isFile && file.name != "star") {
        if (!File("${star.constellation.path}/${file.name}").existsSync()) {
          removedFiles.add(file.name);
        }
      }
    }
    archive.clearSync();
    return removedFiles;
  }

  /// # `Map<String, String>` listMovedFiles(`List<String>` newFiles, `List<String>` removedFiles)
  /// ## Lists all files in the current directory that have been recently moved.
  Map<String, String> _listMovedFiles(
      List<String> newFiles, List<String> removedFiles) {
    Map<String, String> movedFiles = {};
    for (String file in removedFiles) {
      if (newFiles.any((e) => e.getFilename() == file.getFilename())) {
        Plasma externalFile = Plasma.fromFile(File(
            "${star.constellation.path}/${newFiles.firstWhere((e) => e.getFilename() == file.getFilename())}"));
        Plasma internalFile = Plasma.fromStar(star, file);
        if (!externalFile.checkForDifferences(internalFile)) {
          movedFiles[file] =
              newFiles.firstWhere((e) => e.getFilename() == file.getFilename());
        }
      }
    }
    return movedFiles;
  }

  /// # `List<String>` listChangedFiles(`List<String>` removedFiles)
  /// ## Lists all files in the current directory that have been recently changed.
  List<String> _listChangedFiles(List<String> removedFiles) {
    Archive archive = star.getArchive();
    List<String> changedFiles = [];
    for (ArchiveFile file in archive.files) {
      if (file.isFile &&
          file.name != "star" &&
          !removedFiles.contains(file.name)) {
        Plasma internalFile = Plasma.fromStar(star, file.name);
        Plasma externalFile =
            Plasma.fromFile(File("${star.constellation.path}/${file.name}"));
        if (externalFile.checkForDifferences(internalFile)) {
          changedFiles.add(file.name);
        }
      }
    }
    archive.clearSync();
    return changedFiles;
  }
}

/// # `enum` `Origin`
/// ## The origin of a `Plasma` object.
/// The origin can either internal (from a star) or external (from the current directory).
enum Origin { internal, external }

/// # `class` `Plasma`
/// ## A wrapper for the internal and external file systems.
/// Its called plasma because its the biggest building block of a star.
class Plasma {
  Star? star; // The star the plasma is in (only used when plasma is internal).
  String?
      pathInStar; // The path of the plasma in the star (only used when plasma is internal).
  File?
      file; // The file the plasma is wrapped around (only used when plasma is external).
  ByteData? _originalData; // The data of the plasma when it was last loaded.
  final ByteData data; // The current data of the plasma.
  final Origin origin; // The origin of the plasma.

  /// # `Plasma`(`ByteData` data)
  /// DO NOT CALL THIS DIRECTLY, USE ONE OF THE FACTORY METHODS ([Plasma.fromFile], [Plasma.fromStar]).
  Plasma(this.data, this.origin, {this.star, this.file, this.pathInStar}) {
    _originalData = Uint8List.fromList(data.buffer.asUint8List().toList())
        .buffer
        .asByteData();
  }

  /// # `Plasma` fromFile(File file)
  /// ## Creates a new plasma from a file.
  /// The returned plasma will be an external plasma.
  factory Plasma.fromFile(File file) {
    return Plasma(file.readAsBytesSync().buffer.asByteData(), Origin.external,
        file: file);
  }

  /// # `Plasma` fromStar(Star star, String pathInStar)
  /// ## Creates a new plasma from a star and a path in the star.
  /// The returned plasma will be an internal plasma.
  factory Plasma.fromStar(Star star, String pathInStar) {
    Archive? archive = star.getArchive();
    ArchiveFile? file = archive.findFile(pathInStar);
    Plasma plasma = Plasma(
        (file!.content as Uint8List).buffer.asByteData(), Origin.internal,
        star: star, pathInStar: pathInStar);
    file.closeSync();
    archive.clearSync();
    return plasma;
  }

  /// # `void` save()
  /// ## Save changes to the file
  /// Throws an exception if the plasma is internal, as internal plasmas cannot be modified.
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

  /// # `String` getFilename()
  /// ## Returns the filename of the plasma.
  /// The filename will be the same for both internal and external plasma.
  String getFilename() {
    if (origin == Origin.internal) {
      return pathInStar!.getFilename();
    } else {
      return file!.path.getFilename();
    }
  }

  String getExtension() {
    if (origin == Origin.internal) {
      return pathInStar!.getExtension();
    } else {
      return file!.path.getExtension();
    }
  }

  void printSummary() {
    Addon addon = Addon.getInstalledAddonsByFeatureSet(FeatureSets.pattern)
        .firstWhere((e) => (e.getMetadata()["associated-files"] as YamlList)
            .contains(getExtension()));
    print(TreeWidget((addon.context as PatternAddonContext).read(this)));
  }

  /// # `bool` isTracked()
  /// ## Returns `true` if the plasma is tracked in a constellation, `false` otherwise.
  bool isTracked() {
    if (origin == Origin.internal) {
      return true;
    } else {
      return Arceus.doesConstellationExist(path: file!.path);
    }
  }

  /// # `Map<int, int>` unsavedChanges()
  /// ## Returns a map of the unsaved changes in the plasma.
  /// `_originalData` is compared to `data`, where `_originalData` is when it was loaded, and `data` is the modified version.
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

  /// # `DifferenceMap` getDifferences(Plasma other)
  /// ## Compares the current plasma to another plasma.
  /// Returns a map of the differences between the two plasmas.
  /// The keys are the addresses of the differences, and the values are the values at those addresses in the current plasma.
  DifferenceMap getDifferences(Plasma other) {
    final differences = DifferenceMap();
    final maxLength = other.data.lengthInBytes >= data.lengthInBytes
        ? other.data.lengthInBytes
        : data.lengthInBytes;

    for (int i = 0; i < maxLength; ++i) {
      if (i >= data.lengthInBytes) {
        differences.addAddition(i, other.data.getUint8(i));
      } else if (i >= other.data.lengthInBytes) {
        differences.addDeletion(i, data.getUint8(i));
      } else if (data.getUint8(i) != other.data.getUint8(i)) {
        differences.addModify(i, data.getUint8(i), other.data.getUint8(i));
      }
    }
    return differences;
  }

  bool checkForDifferences(Plasma other) => getDifferences(other).hasChanges();

  /// # `Plasma?` findOlderVersion()
  /// ## Returns the older version of the plasma if it exists, or `null` if it doesn't.
  /// The older version will ALWAYS be an internal plasma, as there can only be one version of an external plasma at one time.
  /// If this plasma is external, then the version from the current star in the constellation where it is tracked will be returned.
  /// If this plasma is internal, then the version from the parent star will be returned.
  /// If the plasma is external, BUT it is not tracked, then `null` will be returned.
  Plasma? findOlderVersion() {
    if (origin == Origin.internal) {
      if (star!.parent != null) {
        return Plasma.fromStar(star!.parent!, pathInStar!);
      }
    } else if (origin == Origin.external) {
      if (isTracked()) {
        Constellation x = Arceus.getConstellationFromPath(file!.path)!;
        print(file!.path.fixPath().replaceFirst("${x.path}/", ""));
        return x.starmap?.currentStar!
            .getPlasma(file!.path.fixPath().replaceFirst("${x.path}/", ""));
      }
    }
    return null;
  }
}

enum ChangeOrigin { from, to }

/// # `class` `DifferenceMap`
/// ## Used to organize the differences between two plasmas into maps.
class DifferenceMap {
  Map<int, Map<ChangeOrigin, int>> modifications = {};
  Map<int, int> additions = {};
  Map<int, int> deletions = {};

  void addModify(int address, int from, int to) {
    modifications[address] = {ChangeOrigin.from: from, ChangeOrigin.to: to};
  }

  void addAddition(int address, int value) {
    additions[address] = value;
  }

  void addDeletion(int address, int value) {
    deletions[address] = value;
  }

  bool hasChanges() {
    if (additions.isNotEmpty ||
        deletions.isNotEmpty ||
        modifications.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool isModified(int byteAddress) {
    if (modifications.containsKey(byteAddress)) {
      return true;
    }
    return false;
  }
}

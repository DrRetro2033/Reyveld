import 'dart:io';

import 'package:archive/archive_io.dart';

import 'star.dart';
import 'package:ansix/ansix.dart';
import 'package:cli_spin/cli_spin.dart';
import 'files.dart';
import '../extensions.dart';

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
    var spinner = CliSpin(text: "Checking for new files...").start();
    List<String> newFiles = listAddedFiles();
    spinner.stop();

    // Check for removed files.
    spinner = CliSpin(text: "Checking for removed files...").start();
    List<String> removedFiles = listRemovedFiles();
    spinner.stop();

    // Check for moved files. Done after new and removed files, as they can be used here to make a cross reference.
    spinner = CliSpin(text: "Checking for moved files...").start();
    Map<String, String> movedFiles = listMovedFiles(newFiles, removedFiles);
    if (movedFiles.isNotEmpty) {
      check = true;
      spinner.stop();
      for (String file in movedFiles.keys) {
        print("$file $moveSymbol ${movedFiles[file]}");
      }
    } else {
      spinner.success("There are no moved files.");
    }

    if (newFiles.isNotEmpty) {
      check = true;
      for (String file in newFiles) {
        if (movedFiles.containsValue(file)) {
          continue;
        }
        print("$addSymbol $file");
      }
    } else {
      spinner.success("There are no new files.");
    }

    if (removedFiles.isNotEmpty) {
      check = true;
      for (String file in removedFiles) {
        if (movedFiles.containsKey(file)) {
          continue;
        }
        print("$removeSymbol $file");
      }
    } else {
      spinner.success("There are no removed files.");
    }

    // Check for changed files.
    spinner = CliSpin(text: "Checking for changed files...").start();
    List<String> changedFiles = listChangedFiles(removedFiles);
    if (changedFiles.isNotEmpty) {
      spinner.stop();
      check = true;
      for (String file in changedFiles) {
        print("$modifiedSymbol $file");
      }
    } else {
      spinner.success("There are no changed files.");
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
        ExternalFile externalFile = ExternalFile(
            "${star.constellation.path}/${newFiles.firstWhere((e) => e.getFilename() == file.getFilename())}");
        InternalFile internalFile = InternalFile(star, file);
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
        DossierFile dossierFile = DossierFile(star, "star://${file.name}");
        if (dossierFile.hasChanged()) {
          changedFiles.add(file.name);
        }
      }
    }
    return changedFiles;
  }
}

/// # `class` `DossierFile`
/// ## A wrapper for the internal and external for a single file in both the internal and external file systems.
class DossierFile {
  Star star;
  String path;
  String? filename;
  InternalFile? internalFile;
  ExternalFile? externalFile;

  DossierFile(this.star, this.path) {
    if (path.startsWith(star.constellation.path)) {
      filename = path.makeRelPath(star.constellation.path);
    } else if (path.startsWith("star://")) {
      filename = path.replaceFirst("star://", "");
    } else {
      throw Exception("Invalid path: $path");
    }
    open();
  }

  /// # `void` open()
  /// ## Opens the internal and external version of the file.
  void open() {
    externalFile = ExternalFile("${star.constellation.path}/${filename!}");
    internalFile = InternalFile(star, filename!);
  }

  /// # `bool` hasChanged()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool hasChanged() {
    // ignore: unrelated_type_equality_checks
    return internalFile != externalFile;
  }
}

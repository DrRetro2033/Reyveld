import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:chalkdart/chalkstrings.dart';

import 'package:arceus/version_control/star.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/version_control/plasma.dart';

/// # `class` `Dossier`
/// ## A class that checks for differences between the star and the current directory.
/// There use to be a moved files check, but it was removed because it was not really necessary.
class Dossier {
  /// # `Star` star
  /// ## The star that is being checked against the current directory.
  Star star;

  // The following are used for the CLI:
  final String _addSymbol = "A".bold.greenBright;
  final String _removeSymbol = "D".bold.redBright;
  final String _modifiedSymbol = "M".bold.yellowBright;

  Dossier(this.star);

  /// # `bool` checkForDifferences()
  /// ## Checks to see if the star's contents is different from the current directory.
  bool checkForDifferences([bool silent = true]) {
    bool check =
        false; // The main check. If any of the preceding checks fail, this will be true, which means that there is a difference.
    Archive archive = star.file.getArchive();
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

    List<String> newFiles = listAddedFiles(archive);
    if (!silent) spinner!.stop();
    // Check for removed files.
    if (!silent) {
      spinner = CliSpin(text: " Checking for removed files...").start();
    }
    List<String> removedFiles = listRemovedFiles(archive);
    if (!silent) spinner!.stop();

    // Check for new files.
    if (newFiles.isNotEmpty) {
      check = true;
      spinner?.fail(" New files found:");
      if (!silent) {
        for (String file in newFiles) {
          print("  $_addSymbol $file");
        }
      }
    } else {
      spinner?.success(" There are no new files.");
    }

    // Check for removed files.
    if (removedFiles.isNotEmpty) {
      check = true;
      spinner?.fail(" Removed files found:");
      if (!silent) {
        for (String file in removedFiles) {
          print("  $_removeSymbol $file");
        }
      }
    } else {
      spinner?.success(" There are no removed files.");
    }

    // Check for changed files.
    if (!silent) {
      spinner = CliSpin(text: " Checking for changed files...").start();
    }
    List<String> changedFiles = listChangedFiles(archive, removedFiles);
    if (changedFiles.isNotEmpty) {
      spinner?.fail(" Changed files found:");
      check = true;
      if (!silent) {
        for (String file in changedFiles) {
          print("  $_modifiedSymbol $file");
        }
      }
    } else {
      spinner?.success(" There are no changed files.");
    }
    archive.clearSync();
    return check;
  }

  /// # `List<String>` listAddedFiles()
  /// ## Lists all files in the current directory that have been recently added.
  List<String> listAddedFiles(Archive archive) {
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
    return newFiles;
  }

  /// # `List<String>` listRemovedFiles()
  /// ## Lists all files in the current directory that have been recently removed.
  List<String> listRemovedFiles(Archive archive) {
    List<String> removedFiles = [];
    for (ArchiveFile file in archive.files) {
      if (file.isFile && file.name != "star") {
        if (!File("${star.constellation.path}/${file.name}").existsSync()) {
          removedFiles.add(file.name);
        }
      }
    }
    return removedFiles;
  }

  /// # `List<String>` listChangedFiles(`List<String>` removedFiles)
  /// ## Lists all files in the current directory that have been recently changed.
  List<String> listChangedFiles(Archive archive, List<String> removedFiles) {
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
    return changedFiles;
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/scripting/addon.dart';
import 'package:arceus/scripting/feature_sets/patterns.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/version_control/star.dart';
import 'package:archive/archive_io.dart';

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
    Archive? archive = star.file.getArchive();
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

  /// # `String` getExtension()
  /// ## Returns the extension of the plasma.
  String getExtension() {
    if (origin == Origin.internal) {
      return pathInStar!.getExtension();
    } else {
      return file!.path.getExtension();
    }
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

  /// # `bool` checkForDifferences(Plasma other)
  /// ## Compares the current plasma to another plasma.
  /// Returns `true` if there are differences in the data between the two plasmas, `false` otherwise.
  /// Does not check if path is the same.
  bool checkForDifferences(Plasma other) => getDifferences(other).hasChanges();

  /// # `Plasma?` findOlderVersion()
  /// ## Returns the older version of the plasma if it exists, or `null` if it doesn't.
  /// The older version will ALWAYS be an internal plasma, as there can only be one version of an external plasma at one time.
  /// If this plasma is external, then the version from the current star in the constellation where it is tracked will be returned.
  /// If this plasma is internal, then the version from the parent star will be returned.
  /// If the plasma is external, BUT it is not tracked, then `null` will be returned.
  Plasma? findOlderVersion() {
    if (origin == Origin.internal) {
      return Plasma.fromStar(star!.parent, pathInStar!);
    } else if (origin == Origin.external) {
      if (isTracked()) {
        Constellation x = Arceus.getConstellationFromPath(file!.path)!;
        print(file!.path.fixPath().replaceFirst("${x.path}/", ""));
        return x.starmap.currentStar
            .getPlasma(file!.path.fixPath().replaceFirst("${x.path}/", ""));
      }
    }
    return null;
  }

  /// # dynamic readWithAddon()
  /// ## Returns the data of the plasma as [Map], using an associated addon.
  ReadResult? readWithAddon({String? addonPath}) {
    PatternAddonContext context;
    if (addonPath != null) {
      final addon = Addon(File(addonPath.fixPath()));
      if (addon.featureSet != FeatureSets.pattern) {
        return null;
      } else {
        context = addon.context as PatternAddonContext;
      }
    } else {
      List<Addon> addons =
          Addon.getInstalledAddons().filterByAssociatedFile(getExtension());
      if (addons.isEmpty && !Arceus.isInternal) {
        // print("Unable to find an addon associated with this file!");
        return null;
      }
      context = addons.last.context as PatternAddonContext;
    }

    return context.read(this);
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

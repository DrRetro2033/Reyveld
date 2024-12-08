import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ansix/ansix.dart';

import '../uuid.dart';
import '../arceus.dart';
import '../extensions.dart';
import '../cli.dart';
import 'star.dart';
import 'dossier.dart';
import 'users.dart';

/// # `class` Constellation
/// ## Represents a constellation.
class Constellation {
  /// The name of the constellation.
  late String name;

  /// The path to the folder this constellation is in.
  late String path;

  /// The starmap of the constellation.
  Starmap? starmap;

  /// The user index of the constellation.
  UserIndex? userIndex;

  // Fetches a directory object from the path this constellation is in.
  Directory get directory => Directory(path);

  /// # `bool` doesStarExist(`String` hash)
  /// ## Checks if a star exists in the constellation.
  /// Returns `true` if the star exists, `false` otherwise.
  bool doesStarExist(String hash) => File(getStarPath(hash)).existsSync();

  /// The path to the folder the constellation stores its data in. (The `.constellation` folder)
  String get constellationPath => "$path/.constellation";

  /// Fetches a directory object that represents the `constellationPath` folder.
  Directory get constellationDirectory => Directory(constellationPath);

  /// The path to the folder the constellation stores its addons in.
  String get addonFolderPath => "$constellationPath/addons";

  /// Fetches a directory object that represents the `addonFolderPath` folder.
  Directory get addonDirectory => Directory(addonFolderPath);

  Constellation(
      {String? path, String? name, Iterable<String> users = const ["host"]}) {
    if (path == null && name == null) {
      throw Exception("Must provide either a path or a name.");
    } else if (path == null &&
        name != null &&
        Arceus.doesConstellationExist(name: name)) {
      path = Arceus.getConstellationPath(name)!;
    }
    this.path = path!.fixPath();
    userIndex = UserIndex(constellationPath);
    if (constellationDirectory.existsSync()) {
      // If the constellation already exists, then load
      load();
      if (starmap?.currentStarHash == null) {
        starmap?.currentStarHash = starmap?.rootHash;
        save();
      }
      if (!Arceus.doesConstellationExist(name: this.name)) {
        Arceus.addConstellation(this.name, path);
      }
      return;
    } else if (name != null) {
      // If the constellation does not exist, then create it with the provided name
      this.name = name;
      _createConstellationDirectory();
      userIndex?.createUsers(users);
      starmap = Starmap(this);
      _createRootStar();
      save();
      Arceus.addConstellation(this.name, path);
      return;
    }
    throw Exception(
        "Constellation not found: $constellationPath. If the constellation does not exist, you must provide a name.");
  }

  /// # `void` _createConstellationDirectory()
  /// ## Creates the directory the constellation stores its data in.
  void _createConstellationDirectory() {
    constellationDirectory.createSync();
    if (Platform.isWindows) {
      // Makes constellation folder hidden on Windows.
      Process.runSync('attrib', ['+h', constellationPath]);
    }
  }

  void _createRootStar() {
    starmap?.root =
        Star(this, name: "Initial Star", user: userIndex?.getHostUser());
    starmap?.currentStar = starmap?.root;
    save();
  }

  String generateUniqueStarHash() {
    for (int i = 0; i < 100; i++) {
      String hash = generateUUID();
      if (!(doesStarExist(hash))) {
        return hash;
      }
    }
    throw Exception(
        "Unable to generate a unique star hash. Either you are extremely unlucky or there are no more unique hashes left to use!");
  }

  /// # `String` getStarPath(`String` hash)
  /// ## Returns a path for a star with the given hash.
  String getStarPath(String hash) => "$constellationPath/$hash.star";

  // ============================================================================
  // These methods are for saving and loading the constellation.

  /// # `void` save()
  /// ## Saves the constellation to disk.
  /// This includes the root star and the current star hashes.
  void save() {
    File file = File("$constellationPath/starmap");
    file.createSync();
    file.writeAsStringSync(jsonEncode(toJson()));
  }

  /// # `void` load()
  /// ## Loads the constellation from disk.
  /// This includes the root star and the current star hashes.
  void load() {
    File file = File("$constellationPath/starmap");
    if (file.existsSync()) {
      _fromJson(jsonDecode(file.readAsStringSync()));
    }
  }

  /// # `void` fromJson(`Map<String, dynamic>` json)
  /// ## Converts the JSON data into the data for the constellation.
  /// This is used when loading the constellation from disk, and is internal, so do not call it directly.
  void _fromJson(Map<String, dynamic> json) {
    name = json["name"];
    starmap = Starmap(this, map: json["map"]);
  }

  // ============================================================================

  /// # `Map<String, dynamic>` toJson()
  /// ## Converts the constellation into a JSON map.
  /// This is used when saving the constellation to disk, and is internal, so do not call it directly.
  Map<String, dynamic> toJson() => {"name": name, "map": starmap?.toJson()};

  /// # `String?` grow(`String` name)
  /// ## Creates a new star with the given name and returns the hash of the new star at the current star.
  String? grow(String name, {bool force = false}) {
    return starmap?.currentStar?.createChild(name, force: force);
  }

  /// # `void` delete()
  /// ## Deletes the constellation from disk.
  /// This will also delete all of the stars in the constellation.
  void delete() {
    Arceus.removeConstellation(name);
    constellationDirectory.deleteSync(recursive: true);
    starmap = null;
  }

  /// # `void` trim()
  /// ## Trims the given or current star and all of its children out of the tree.
  void trim([Star? star]) {
    starmap?.trim(star);
  }

  /// # `void` resetToCurrentStar()
  /// ## Restores the files from current star.
  /// This WILL discard any changes in files, so make sure you grown the constellation before calling this.

  void resetToCurrentStar() {
    starmap?.currentStar?.makeCurrent();
  }

  /// # `void` clear()
  /// ## Clears all files in the associated path, expect for the `.constellation` folder.
  void clear() {
    directory.listSync(recursive: true).forEach((entity) {
      if (entity is File &&
          !entity.path.fixPath().contains(constellationPath.fixPath())) {
        entity.deleteSync();
      }
    });
  }

  /// # `bool` checkForDifferences()
  /// ## Checks if the constellation has differences between the current star and the root star.
  /// Returns `true` if there are differences, `false` otherwise.
  bool checkForDifferences([bool showResults = false]) {
    Star star = Star(this, hash: starmap?.currentStarHash);
    return Dossier(star).checkForDifferences(showResults);
  }

  /// # `bool` checkForConstellation(`String` path)
  /// ## Checks if the constellation exists at the given path.
  /// Returns `true` if the constellation exists, `false` otherwise.
  static bool checkForConstellation(String path) {
    return Directory("$path/.constellation").existsSync();
  }
}

/// # `class` Starmap
/// ## Represents the relationship between stars.
/// This now contains the root star and the current star.
/// It also contains the children and parents of each star, in two separate maps, for performance and ease reading and writing.
class Starmap {
  Constellation constellation;

  // Maps for storing children and parents.
  Map<String, List<dynamic>> childMap = {}; // Format: {parent: [children]}
  Map<String, dynamic> parentMap = {}; // Format: {child: parent}

  Starmap(this.constellation, {Map<dynamic, dynamic>? map}) {
    if (map == null) {
      childMap = {};
      parentMap = {};
    } else {
      fromJson(map);
    }
  }

  String? rootHash; // The hash of the root star.
  Star? get root => Star(constellation,
      hash: rootHash!); // Fetches the root star as a Star object.
  set root(Star? value) => rootHash =
      value?.hash; // Sets the root star hash with the given Star object.
  String? currentStarHash; // The hash of the current star.
  Star? get currentStar => Star(constellation,
      hash: currentStarHash!); // Fetches the current star as a Star object.
  set currentStar(Star? value) => currentStarHash =
      value?.hash; // Sets the current star hash with the given Star object.

  /// # `void` initEntry(`String` hash)
  /// ## Initializes the entry for the given hash.
  /// Called by `Star` when a new star is created.
  void initEntry(String hash) {
    if (childMap[hash] != null) {
      return;
    }
    childMap[hash] = [];
  }

  /// # `void` jumpTo(`String?` hash)
  /// ## Changes the current star to the star with the given hash.
  void jumpTo(String? hash) {
    if (constellation.doesStarExist(hash ?? rootHash!)) {
      currentStar = Star(constellation, hash: hash ?? rootHash!);
    }
  }

  /// # `Star` getMostRecentStar()
  /// ## Returns the most recent star that was created in the constellation.
  /// Will first get all the ending stars, then find the one with the most recent creation date.
  Star getMostRecentStar() {
    List<Star> endings = getEndings();
    if (endings.isEmpty) {
      throw Exception("WHAT? How are there no ending stars?");
    }
    Star mostRecentStar = endings.first;
    for (int i = 1; i < endings.length; i++) {
      Star star = endings[i];
      if (mostRecentStar.createdAt!.compareTo(star.createdAt!) < 0) {
        mostRecentStar = star;
      }
    }
    return mostRecentStar;
  }

  /// # `operator` [](`Star` star)
  /// ## Get the star with the given hash.
  /// Pass a hash to get the star with that hash.
  /// There are some keywords that you can use instead of a hash. Any keywords below can be chained together with `;`:
  /// - `root`: The root star
  /// - `recent`: The most recent star
  /// - `back`: The parent of the current star. Will be clamped to the root star.
  /// - `back X`: Will return the first child of every star preceeding the current star by X. Will be clamped to the the root star.
  /// - `forward`: Will return the first child from the current star. Will be clamped to any ending stars.
  /// - `forward X`: Will return the first child of every star proceeding the current star by X. Will be clamped to any ending stars.
  /// - `above`: The sibling above the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - `above X`: The Xth sibling above the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - `below`: The sibling below the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - `below X`: The Xth sibling below the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - `next X`: Will return the Xth child of the current star. Will be wrapped to a vaild index of the current star's children.
  operator [](Object hash) {
    if (hash is String) {
      List<String> commands = hash.split(",");
      Star current = currentStar!;
      for (String command in commands) {
        if (command == "recent") {
          current = getMostRecentStar();
        } else if (command == "root") {
          current = root!;
        } else if (command.startsWith("forward")) {
          final x = command.replaceFirst("forward", "");
          int? i = int.tryParse(x);
          if (i == null) {
            current = current.getChild(0);
            continue;
          }
          Star? star = current;
          while (i! > 0) {
            if (star!.children.isEmpty) {
              break;
            }
            star = star.getChild(0);
            i--;
          }
          current = star!;
        } else if (command.startsWith("back")) {
          final x = command.replaceFirst("back", "");
          int? i = int.tryParse(x);
          if (i == null) {
            current = current.parent!;
            continue;
          }
          Star? star = current;
          while (i! > 0) {
            if (star!.isRoot) {
              break;
            }
            star = star.parent;
            i--;
          }
          current = star!;
        } else if (command.startsWith("above")) {
          final x = command.replaceFirst("above", "");
          int i = int.tryParse(x) ?? 1;
          current = current.getSibling(above: i);
        } else if (command.startsWith("below")) {
          final x = command.replaceFirst("below", "");
          int i = int.tryParse(x) ?? 1;
          current = current.getSibling(below: i);
        } else if (command.startsWith("next")) {
          final x = command.replaceFirst("next", "");
          int? i = int.tryParse(x);
          if (i == null) throw Exception("Please provide an index.");
          current = current.getChild(i - 1);
        } else if (constellation.doesStarExist(hash)) {
          current = Star(constellation, hash: hash);
        }
      }
      return current;
    }
  }

  /// # `Map` toJson()
  /// ## Returns a JSON map of the starmap.
  /// This is used when saving the starmap to disk.
  Map<dynamic, dynamic> toJson() {
    childMap.removeWhere((key, value) => value.isEmpty);
    return {
      "root": rootHash,
      "current": currentStarHash,
      "children": childMap,
      "parents": parentMap
    };
  }

  /// # `void` fromJson(`Map` json)
  /// ## Uses a JSON map to initialize the starmap.
  /// This is used when loading the starmap from disk.
  void fromJson(Map<dynamic, dynamic> json) {
    rootHash = json["root"];
    currentStarHash = json["current"];
    for (String hash in json["children"].keys) {
      childMap[hash] = json["children"][hash];
    }
    for (String hash in json["parents"].keys) {
      parentMap[hash] = json["parents"][hash];
    }
  }

  /// # `List<Star>` getChildren(`Star` parent)
  /// ## Returns a list of all children of the given parent.
  /// The list will be empty if the parent has no children.
  List<Star> getChildren(Star parent) {
    List<Star> children = [];
    for (String hash in getChildrenHashes(parent.hash!)) {
      children.add(Star(constellation, hash: hash));
    }
    return children;
  }

  /// # `List<String>` getChildrenHashes(`String` parent)
  /// ## Returns a list of all children hashes of the given parent.
  /// The list will be empty if the parent has no children.
  List getChildrenHashes(String parent) {
    return childMap[parent] ?? <String>[];
  }

  /// # `void` addRelationship(`Star` parent, `Star` child)
  /// ## Adds the given child to the given parent.
  /// Throws an exception if the child already has a parent.
  void addRelationship(Star parent, Star child) {
    if (parentMap[child.hash] != null) {
      throw Exception("Star already has a parent.");
    }

    if (childMap[parent.hash] == null) {
      childMap[parent.hash!] = [];
    }
    childMap[parent.hash!]?.add(child.hash!);
    parentMap[child.hash!] = parent.hash!;
    constellation.save();
  }

  /// # `void` printMap()
  /// ## Prints the constellation's stars.
  /// This is a tree view of the constellation's stars and their children.
  void printMap() {
    print(AnsiTreeView(_getTree(root!, {}), theme: Cli.treeTheme));
  }

  /// # `Map<String, dynamic>` _getTree(`Star` star, `Map<String, dynamic>` tree, {`bool` branch = false})
  /// ## Returns the tree of the star and its children, for printing.
  /// This is called recursively, to give a resonable formatting to the tree, by making single children branches be in one column, instead of infinitely nested.
  Map<String, dynamic> _getTree(Star star, Map<String, dynamic> tree,
      {bool branch = false}) {
    tree[star.getDisplayName()] = {};
    if (star.singleChild) {
      if (branch) {
        tree[star.getDisplayName()].addAll(_getTree(star.children.first, {}));
        return tree;
      }
      return _getTree(star.children.first, tree);
    } else {
      for (Star child in getChildren(star)) {
        tree[star.getDisplayName()].addAll(_getTree(child, {}, branch: true));
      }
    }
    return tree;
  }

  /// # `void` trim(`Star` star)
  /// ## Trims the given star and all of its children.
  /// This will not discard any changes in files, BUT will destroy previous changes in files.
  void trim([Star? star]) {
    star ??= currentStar!; // If no star is given, use the current star.
    star.parent!.makeCurrent();
    star.trim(); // Calls the trim function on the star.
    constellation.save();
  }

  /// # `void` sterilizeStar(`Star` star)
  /// ## Will safely remove the given star's relationships from the starmap. Remember to call `save()` in the constellation afterwards.
  void sterilizeStar(Star star) {
    if (star.isRoot) {
      throw Exception("Cannot sterilize the root star!");
    }
    _removeFromTree(star);
  }

  void _removeFromTree(Star star) {
    star.parent?.removeChild(star);
    parentMap.remove(star.hash);
    if (childMap.containsKey(star.hash)) {
      childMap.remove(star.hash);
    }
  }

  /// # `List<Star>` getStarsAtDepth(`int` depth)
  /// ## Returns a list of all stars at the given depth.
  List<Star> getStarsAtDepth(int depth) {
    List<Star> stars = [root!];
    while (depth > 0) {
      List<Star> newStars = [];
      for (Star star in stars) {
        newStars.addAll(star.children);
      }
      if (newStars.isEmpty) {
        break;
      }
      stars = newStars;
      depth--;
    }
    return stars;
  }

  List<Star> getEndings() {
    List<Star> endings = [];
    List<Star> stars = [root!];
    while (stars.isNotEmpty) {
      List<Star> newStars = [];
      for (Star star in stars) {
        if (star.hasNoChildren) {
          endings.add(star);
        } else {
          newStars.addAll(star.children);
        }
      }
      stars = newStars;
    }
    return endings;
  }

  /// # `bool` existAtCoordinates(`int` depth, `int` index)
  /// ## Returns true if a star exists at the given depth and index.
  /// Returns false otherwise.
  bool existAtCoordinates(int depth, int index) {
    List<Star> stars = getStarsAtDepth(depth);
    if (index >= 0 && index < stars.length) {
      return true;
    }
    return false;
  }

  /// # `bool` existBesideCoordinates(`int` depth, `int` index)
  /// ## Returns true if a star exists at the given depth and index.
  /// Returns false otherwise.
  bool existBesideCoordinates(int depth, int index) {
    if (existAtCoordinates(depth, index - 1) ||
        existAtCoordinates(depth, index + 1)) {
      return true;
    }
    return false;
  }
}

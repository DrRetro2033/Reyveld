import 'dart:convert';
import 'dart:io';
import 'package:arceus/updater.dart';
import 'package:arceus/widget_system.dart';
import 'package:arceus/uuid.dart';
import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/version_control/star.dart';
import 'package:arceus/version_control/plasma.dart';
import 'package:arceus/version_control/dossier.dart';
import 'package:arceus/version_control/users.dart';
import 'package:archive/archive_io.dart';
import 'package:cli_spin/cli_spin.dart';

/// # class Constellation
/// ## Represents a constellation.
class Constellation {
  /// # String name
  /// ## The name of the constellation.
  String name = "";

  /// # late String path
  /// ## The path to the folder the constellation is in (not the .constellation folder).
  late String path;

  /// # [Starmap] starmap
  /// ## The starmap of the constellation.
  /// No extra action is needed to load the starmap, as it is automatically loaded when the constellation is loaded.
  late Starmap starmap;

  /// # [UserIndex] get userIndex
  /// ## The user index of the constellation.
  /// The index used to be stored in the .constellation folder,
  /// but it is now stored in the AppData folder, and is shared across all constellations.
  UserIndex get userIndex => Arceus.userIndex;

  /// # [Directory] get directory
  /// ## Fetches a directory object that represents the folder the constellation is in.
  Directory get directory => Directory(path);

  /// # bool doesStarExist(String hash)
  /// ## Checks if a star exists in the constellation.
  /// Returns true if the star exists, false otherwise.
  bool doesStarExist(String hash) => File(getStarPath(hash)).existsSync();

  /// The path to the folder the constellation stores its data in. (The .constellation folder)
  String get constellationPath => "$path/.constellation";

  /// # [Directory] get constellationDirectory
  /// ## Fetches a directory object that represents the constellationPath folder
  Directory get constellationDirectory => Directory(constellationPath);

  /// # String get addonFolderPath
  /// ## Returns the path to the folder the constellation stores its local addons in.
  String get addonFolderPath => "$constellationPath/addons";

  /// # [Directory] get addonDirectory
  /// ## Fetches a directory object that represents the addonFolderPath folder.
  Directory get addonDirectory => Directory(addonFolderPath);

  String? _loggedInUserHash;

  /// # [User] loggedInUser
  /// ## The user that is currently logged into the constellation.
  User get loggedInUser {
    if (_loggedInUserHash != null) {
      return userIndex.getUser(_loggedInUserHash!);
    }
    return starmap.currentStar.user;
  }

  set loggedInUser(User user) {
    _loggedInUserHash = user.hash;
  }

  String? summaryFile;

  /// # Constellation({String? path, String? name})
  /// ## Creates a new constellation.
  /// If a path or name is provided, then the constellation will be loaded from that path, if it exists.
  /// If the constellation does not exist with the provided name or path, then both a name and path must be provided.
  Constellation({String? path, String? name, User? user}) {
    if (path == null && name == null) {
      throw Exception("Must provide either a path or a name.");
    } else if (path == null &&
        name != null &&
        Arceus.doesConstellationExist(name: name)) {
      path = Arceus.getConstellationPath(name)!;
    }
    this.path = path!.fixPath();
    if (constellationDirectory.existsSync()) {
      // If the constellation already exists, then load
      try {
        _load();
      } catch (e, st) {
        Arceus.talker.error("Failed to load constellation at $path.", e, st);
      }
      // if (name == null) {
      //   return;
      // }
      if (!Arceus.doesConstellationExist(name: this.name)) {
        Arceus.addConstellation(this.name, path);
      }
    } else if (name != null) {
      // If the constellation does not exist, then create it with the provided name
      _createConstellationDirectory(path);
      starmap = Starmap(this);
      _createRootStar(user);
      save();
      Arceus.addConstellation(name, path);
      Arceus.talker
          .info("Created a new constellation named '$name' at '$path'.");
    } else {
      Arceus.talker.error("Constellation does not exist at path! $path",
          Exception("Does not exist"), StackTrace.current);
    }
  }

  /// # void _createConstellationDirectory()
  /// ## Creates the directory the constellation stores its data in.
  /// On Linux and MacOS, no extra action is needed to hide the folder.
  /// On Windows however, an attribute needs to be set to hide the folder.
  static void _createConstellationDirectory(String path) {
    String constellationPath = "$path/.constellation";
    Directory constellationDirectory = Directory(constellationPath);
    constellationDirectory.createSync();
    if (Platform.isWindows) {
      // Makes constellation folder hidden on Windows.
      Process.runSync('attrib', ['+h', constellationPath]);
    }
  }

  /// # void _createRootStar()
  /// ## Creates the root star of the constellation.
  /// Called when the constellation is created.a
  /// Does not need to be called manually.
  void _createRootStar(User? user) {
    starmap.root = Star.create(this, "Initial Star",
        user: user ?? userIndex.getHostUser());
    starmap.currentStar = starmap.root;
    save();
  }

  /// # String generateUniqueStarHash()
  /// ## Generates a unique star hash.
  String generateUniqueStarHash() {
    return generateUniqueHash(listStarHashes());
  }

  /// # String getStarPath(String hash)
  /// ## Returns a path for a star with the given hash.
  String getStarPath(String hash, {bool temp = false}) =>
      "$constellationPath/${temp ? "temp_" : ""}$hash.star";

  /// # List<String> listStarFiles()
  /// ## Lists all stars in the constellation.
  /// Returns a list of the hashes of all stars in the constellation folder (NOT the starmap).
  /// Used for recovering a constellation from corruption.
  Set<String> listStarHashes() {
    Set<String> stars = {};
    for (String hash in Directory(constellationPath)
        .listSync()
        .map((e) => e.path)
        .toList()) {
      if (hash.getExtension() == "star") {
        stars.add(hash.getFilename(withExtension: false));
      }
    }
    return stars;
  }

  // ============================================================================
  // These methods are for saving and loading the constellation.

  /// # void save()
  /// ## Saves the constellation to disk.
  /// This includes the root star and the current star hashes.
  void save() {
    File file = File("$constellationPath/starmap");
    file.createSync();
    file.writeAsStringSync(jsonEncode(toJson()));
    Arceus.talker.info("Saved constellation '$name'.");
  }

  /// # void load()
  /// ## Loads the constellation from disk.
  /// This includes the root star and the current star hashes.
  void _load() {
    File file = File("$constellationPath/starmap");
    if (file.existsSync()) {
      try {
        _fromJson(jsonDecode(file.readAsStringSync()));
      } catch (e, st) {
        Arceus.talker.error("Failed to load constellation at $path.", e, st);
      }
    } else {
      Arceus.talker.error("Constellation does not exist at path! $path",
          Exception("Does not exist"), StackTrace.current);
    }
  }

  /// # void fromJson(Map<String, dynamic> json)
  /// ## Converts the JSON data into the data for the constellation.
  /// This is used when loading the constellation from disk, and is internal, so do not call it directly.
  void _fromJson(Map<String, dynamic> json) {
    name = json["name"];
    starmap = Starmap(this, map: json["map"]);
    if (json.containsKey("loggedInUser")) {
      if (json["loggedInUser"] != null) {
        _loggedInUserHash = json["loggedInUser"];
      }
    }
  }

  /// # Map<String, dynamic> toJson()
  /// ## Converts the constellation into a JSON map.
  /// This is used when saving the constellation to disk, and is internal, so do not call it directly.
  Map<String, dynamic> toJson() => {
        "name": name,
        "loggedInUser": loggedInUser.hash,
        "map": starmap.toJson()
      };

  // ============================================================================

  /// # String? grow(String name)
  /// ## Creates a new star with the given name and returns the hash of the new star at the current star.
  Star? grow(String name, {bool force = false, bool signIn = true}) {
    User? user = loggedInUser;
    if (signIn) {
      user = Arceus.userSelect(prompt: "Assign Star to...");
      if (user == null) return null;
    }
    return starmap.currentStar.createChild(name, force: force, user: user);
  }

  String getAutoStarName() {
    final autoName = "Auto Star";
    final prevStar = starmap.currentStar;
    if (prevStar.name.startsWith("Auto Star")) {
      int i =
          int.tryParse(prevStar.name.replaceFirst(autoName, "").trim()) ?? 1;
      return "$autoName ${i + 1}";
    }
    return autoName;
  }

  static void deleteStatic(String path) {
    Arceus.removeConstellation(path: path);
    final dir = Directory("$path/.constellation");
    if (!dir.existsSync()) return;
    dir.deleteSync(recursive: true);
    Arceus.talker.info("Staticly deleted constellation at '$path'.");
  }

  /// # void delete()
  /// ## Deletes the constellation from disk.
  /// This will also delete all of the stars in the constellation.
  void delete() {
    Arceus.removeConstellation(path: path);
    constellationDirectory.deleteSync(recursive: true);
    Arceus.talker.info("Deleted constellation '$name' at '$path'.");
  }

  /// # void trim()
  /// ## Trims the given or current star and all of its children out of the tree.
  void trim([Star? star]) {
    starmap.trim(star);
  }

  /// # void resyncToCurrentStar()
  /// ## Restores the files from current star.
  /// This WILL discard any changes in files, so make sure you grown the constellation before calling this.
  void resyncToCurrentStar() {
    starmap.currentStar.resync();
  }

  /// # void clear()
  /// ## Clears all files in the associated path, except for the .constellation folder and its contents.
  void clear() {
    directory.listSync(recursive: true).forEach((entity) {
      if (entity is File &&
          !entity.path.fixPath().contains(constellationPath.fixPath())) {
        entity.deleteSync();
      }
    });
  }

  /// # void loginAs([User] user)
  /// ## Sets the logged in user to the given user.
  /// This will also save the constellation with the new logged in user.
  void loginAs(User user) {
    loggedInUser = user;
    save();
    Arceus.talker.info("Logged in as '${user.name}'.");
  }

  /// # bool checkForDifferences()
  /// ## Checks if the constellation has differences between the current star and the root star.
  /// Returns true if there are differences, false otherwise.
  /// If silent is true (default), will not print any output.
  /// If silent is false, will print the differences to the console.
  bool checkForDifferences([bool silent = true]) {
    return Dossier(starmap.currentStar).checkForDifferences(silent);
  }

  /// # bool checkForConstellation(String path)
  /// ## Checks if the constellation exists at the given path.
  /// Returns true if the constellation exists, false otherwise.
  static bool exists(String path) {
    if (Directory("$path/.constellation").existsSync() &&
        File("$path/.constellation/starmap").existsSync()) {
      return true;
    }
    return false;
  }

  void printSumOfCurStar() {
    if (summaryFile == null) {
      return;
    }
    Plasma plasma = starmap.currentStar.getPlasma(summaryFile!);
    print(TreeWidget(plasma.readWithAddon()!.data));
  }

  static List<StarFile>? listStarFiles(String path) {
    final directory = Directory("${Arceus.currentPath}/.constellation");
    if (!directory.existsSync()) {
      return null;
    }
    final files = directory.listSync().cast<FileSystemEntity>();
    files.removeWhere((e) => !e.path.endsWith(".star"));
    final starfiles = files.map((e) => StarFile(e.path)).toList();
    return starfiles;
  }

  ConstellationPackage package(String to) {
    save();
    final package = ConstellationPackage.compress(this, to);
    Arceus.talker.info("Packed constellation to '$to'.");
    return package;
  }

  /// # static Constellation unpackage(ConstellationPackage package, String toPath)
  /// ## Unpackages the given constellation package to the given path.
  /// If a constellation already exists at the given path, then a merge will be performed.
  /// If the roots of both constellations are different, then an error will be thrown.
  static Constellation unpackage(ConstellationPackage package, String toPath) {
    String path = toPath;
    bool constExists = false;
    if (Constellation.exists(toPath)) {
      path = Arceus.getTempFolder();
      constExists = true;
    }
    Constellation._createConstellationDirectory(path);
    package.unpack(path);
    final constellationNew = Constellation(path: path);
    if (constExists) {
      final constellationOld = Constellation(path: toPath);
      constellationOld.merge(constellationNew, deleteOther: false);
      Arceus.talker.info(
          "Merged packed constellation '${constellationNew.name}' into '${constellationOld.name}'.");
      return constellationOld;
    } else {
      Arceus.talker.info(
          "Extracted packed constellation '${constellationNew.name}' to '${constellationNew.path}'.");
    }
    constellationNew.resyncToCurrentStar();
    return constellationNew;
  }

  void merge(Constellation other, {bool deleteOther = false}) {
    starmap.merge(other.starmap);
    if (deleteOther) {
      other.delete();
    }
    save();
  }
}

/// # class Starmap
/// ## Represents the relationship between stars.
/// This now contains the root star and the current star.
/// It also contains the children and parents of each star, in two separate maps, for performance and ease reading and writing.
class Starmap {
  Constellation constellation;

  final Map<String, String> _parentMap = {}; // Format: {child: parent}

  /// # late String _rootHash
  /// ## The hash of the root star.
  late String _rootHash;
  Star get root =>
      Star(constellation, _rootHash); // Fetches the root star as a Star object.
  set root(Star value) => _rootHash =
      value.hash; // Sets the root star hash with the given Star object.

  String? _currentStarHash;
  Star get currentStar {
    if (!constellation.doesStarExist(_currentStarHash ?? "")) {
      return root;
    } else {
      return Star(constellation,
          _currentStarHash!); // Fetches the current star as a Star object.
    }
  }

  set currentStar(Star value) => _currentStarHash = value.hash;

  Starmap(this.constellation, {Map<dynamic, dynamic>? map}) {
    if (map != null) {
      fromJson(map);
    }
  }

  /// # [Star] getMostRecentStar()
  /// ## Returns the most recent star that was created in the constellation.
  /// Will first get all the ending stars, then find the one with the most recent creation date.
  Star getMostRecentStar({bool forceUser = false}) {
    List<Star> endings = getEndings();
    if (endings.isEmpty) {
      throw Exception("WHAT? How are there no ending stars?");
    }
    final userEndings =
        endings.where((element) => element.user == constellation.loggedInUser);
    if (userEndings.isNotEmpty) {
      endings = userEndings.toList();
    } else if (forceUser) {
      return currentStar;
    }
    Star mostRecentStar = endings.first;

    for (int i = 1; i < endings.length; i++) {
      Star star = endings[i];
      if (mostRecentStar.createdAt.compareTo(star.createdAt) < 0) {
        mostRecentStar = star;
      }
    }
    return mostRecentStar;
  }

  /// # operator []([Star] star)
  /// ## Get the star with the given hash.
  /// Pass a hash to get the star with that hash.
  /// There are some keywords that you can use instead of a hash. Any keywords below can be chained together with ;:
  /// - root: The root star
  /// - recent: The most recent star
  /// - back: The parent of the current star. Will be clamped to the root star.
  /// - back X: Will return the first child of every star preceeding the current star by X. Will be clamped to the the root star.
  /// - forward: Will return the first child from the current star. Will be clamped to any ending stars.
  /// - forward X: Will return the first child of every star proceeding the current star by X. Will be clamped to any ending stars.
  /// - above: The sibling above the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - above X: The Xth sibling above the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - below: The sibling below the current star. If the sibling doesn't exist, it will try and find a sibling of one of its parents. If that doesn't exist, it will return the root star.
  /// - below X: The Xth sibling below the current star. If the sibling doesn't exist, it will try and find the next available sibling of one of its parents. If that doesn't exist, it will return the root star. Will be wrapped if there is a sibling.
  /// - next X: Will return the Xth child of the current star. Will be wrapped to a valid index of the current star's children.
  operator [](Object hash) {
    if (hash is String) {
      List<String> commands = hash.split(",");
      Star current = currentStar;
      for (String command in commands) {
        command = command.trim(); // Remove any whitespace.
        if (command == "recent") {
          // Jump to most recent star.
          current = getMostRecentStar();
        } else if (command == "root") {
          // Jump to root star.
          current = root;
        } else if (command.startsWith("forward")) {
          // Jump forward by X stars.
          final x = command.replaceFirst("forward", "");
          int i = int.tryParse(x) ?? 1;
          Star star = current;
          while (i > 0) {
            star = star.getChild(0);
            i--;
          }
          current = star;
        } else if (command.startsWith("back")) {
          // Jump back by X stars.
          final x = command.replaceFirst("back", "");
          int? i = int.tryParse(x.trim()) ?? 1;
          Star star = current;
          while (i! > 0) {
            star = star.parent;
            i--;
          }
          current = star;
        } else if (command.startsWith("above")) {
          // Jump above
          final x = command.replaceFirst("above", "");
          int i = int.tryParse(x) ?? 1;
          current = current.getSibling(above: i);
        } else if (command.startsWith("below")) {
          // Jump below
          final x = command.replaceFirst("below", "");
          int i = int.tryParse(x) ?? 1;
          current = current.getSibling(below: i);
        } else if (command.startsWith("next")) {
          // Jump to next child
          final x = command.replaceFirst("next", "");
          int? i = int.tryParse(x) ?? 1;
          current = current.getChild(i - 1);
        } else if (command.startsWith("depth")) {
          // Jump to depth
          final x = command.replaceFirst("depth", "");
          int? i = int.tryParse(x) ?? 1;
          current = getStarsAtDepth(i)[0];
        } else if (constellation.doesStarExist(hash)) {
          current = Star(constellation, hash);
        }
      }
      return current;
    }
  }

  /// # Map<dynamic, dynamic> toJson()
  /// ## Returns a JSON map of the starmap.
  /// This is used when saving the starmap to disk.
  Map<dynamic, dynamic> toJson() {
    return {
      "root": _rootHash,
      "current": _currentStarHash,
      "parents": _parentMap
    };
  }

  /// # void fromJson(Map<dynamic, dynamic> json)
  /// ## Uses a JSON map to initialize the starmap.
  /// This is used when loading the starmap from disk.
  void fromJson(Map<dynamic, dynamic> json) {
    _rootHash = json["root"];
    _currentStarHash = json["current"];
    _parentMap.addAll((json["parents"]).cast<String, String>());
  }

  Star? getParent(Star star) {
    try {
      return Star(constellation, _parentMap[star.hash]!);
    } catch (e) {
      return null;
    }
  }

  /// # List<[Star]> getChildren([Star] parent)
  /// ## Returns a list of all children of the given parent.
  /// The list will be empty if the parent has no children.
  List<Star> getChildren(Star parent) {
    List<Star> children = [];
    for (String hash in _getChildrenHashes(parent.hash)) {
      children.add(Star(constellation, hash));
    }
    return children;
  }

  /// # List<String> getChildrenHashes(String parent)
  /// ## Returns a list of all children hashes of the given parent.
  /// The list will be empty if the parent has no children.
  List<String> _getChildrenHashes(String hash) {
    return _parentMap.entries
        .where((e) => e.value == hash)
        .map((e) => e.key)
        .toList();
  }

  /// # void addRelationship([Star] parent, [Star] child)
  /// ## Adds the given child to the given parent.
  /// Throws an exception if the child already has a parent.
  void addRelationship(Star parent, Star child, {bool save = true}) {
    _parentMap.putIfAbsent(child.hash, () => parent.hash);
    if (save) constellation.save();
  }

  /// # void printMap()
  /// ## Prints the constellation's stars.
  /// This is a tree view of the constellation's stars and their children.
  void printMap() {
    final spinner =
        CliSpin(text: " Generating map...", spinner: CliSpinners.moon).start();
    final tree = TreeWidget(_getTree(root, {}));
    spinner.stop();
    print(tree);
  }

  /// # Map<String, dynamic> _getTree([Star] star, Map<String, dynamic> tree, {bool branch = false})
  /// ## Returns the tree of the star and its children, for printing.
  /// This is called recursively, to give a reasonable formatting to the tree, by making single children branches be in one column, instead of infinitely nested.
  Map<String, dynamic> _getTree(Star star, Map<String, dynamic> tree,
      {bool branch = false}) {
    tree[star.getDisplayName()] = <String, dynamic>{};
    if (star.hasSingleChild) {
      if (branch) {
        tree[star.getDisplayName()].addAll(_getTree(star.singleChild, {}));
        return tree;
      }
      return _getTree(star.singleChild, tree);
    } else {
      for (Star child in getChildren(star)) {
        tree[star.getDisplayName()].addAll(_getTree(child, {}, branch: true));
      }
    }
    return tree;
  }

  /// # void trim([Star] star)
  /// ## Trims the given star and all of its children.
  /// This will not discard any changes in files, BUT will destroy previous changes in files.
  void trim([Star? star]) {
    star ??= currentStar; // If no star is given, use the current star.
    if (star.isRoot) {
      print("Cannot trim the root star!");
      return;
    }
    star.parent.makeCurrent(save: false);
    star.trim(); // Calls the trim function on the star.
    constellation.save();
  }

  /// # void sterilizeStar([Star] star)
  /// ## Will safely remove the given star's relationships from the starmap.
  /// Remember to call [Constellation.save] in the constellation afterwards.
  void sterilizeStar(Star star) {
    if (star.isRoot) {
      throw Exception("Cannot sterilize the root star!");
    }
    _removeFromTree(star);
  }

  void _removeFromTree(Star star) {
    _parentMap.remove(star.hash); // Remove the star from the parent map.
  }

  /// # List<[Star]> getStarsAtDepth(int depth)
  /// ## Returns a list of all stars at the given depth.
  List<Star> getStarsAtDepth(int depth, {bool allowEmpty = false}) {
    List<Star> stars = [root];
    while (depth > 0) {
      List<Star> newStars = [];
      for (Star star in stars) {
        newStars.addAll(star.children);
      }
      if (newStars.isEmpty && !allowEmpty) {
        break;
      }
      stars = newStars;
      depth--;
    }
    return stars;
  }

  /// # List<[Star]> getEndings()
  /// ## Returns a list of all ending stars in the constellation.
  /// An ending star is a star that has no children.
  List<Star> getEndings() {
    List<Star> endings = [];
    List<Star> stars = [root];
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

  /// # bool moreExistAtDepth(int depth, [Star] star)
  /// ## Returns true if there is a star at the given depth that is not the given star.
  /// Returns false otherwise.
  bool moreExistAtDepth(int depth, Star star) {
    final stars = getStarsAtDepth(depth);
    stars.removeWhere(
        (element) => element == star || element.isAncestorOf(star));
    return stars.isNotEmpty;
  }

  bool existAtDepth(int depth) {
    return getStarsAtDepth(depth, allowEmpty: true).isNotEmpty;
  }

  void merge(Starmap other) {
    if (!other.root.exactlyMatches(root)) {
      // If the roots are different, throw an error.
      Arceus.talker.error("Cannot merge constellations with different roots.",
          Exception("Different roots!"), StackTrace.current);
    }

    int depth = 1;
    while (other.existAtDepth(depth)) {
      List<Star> starsToCopy = other.getStarsAtDepth(depth);
      // Remove the stars that are already in the starmap, and add the new stars.
      // starsToCopy.removeWhere(
      //     (x) => getStarsAtDepth(depth).any((y) => y.exactlyMatches(x)));
      for (Star star in starsToCopy) {
        star.copyTo(constellation);
      }
      depth++;
    }
  }
}

/// # class ConstellationPackage
/// ## A class that represents a constellation package.
/// This clas represents a ".constpack" file.
/// Can be used to both share save data between users, but also make cloud syncing possible.
class ConstellationPackage {
  final String path;

  ConstellationPackage(this.path);

  String get name => _getDetails()["name"];

  String get hostname => _getDetails()["hostname"];

  String get version => _getDetails()["version"];

  DateTime get date => DateTime.parse(_getDetails()["date"]);

  /// # [Archive] getArchive()
  /// ## Returns the archive of the star.
  /// ALWAYS, ALWAYS, ALWAYS call [Archive.clearSync] on the archive object after using it.
  /// If you don't, then trimming a star will not work, and will throw an access error.
  Archive _getArchive() {
    final inputStream = InputFileStream(path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    return archive;
  }

  factory ConstellationPackage.compress(
      Constellation constellation, String output) {
    ZipFileEncoder archive = ZipFileEncoder();
    String to = "";
    if (output.endsWith(".constpack")) {
      to = output;
    } else if (Directory(output).existsSync()) {
      to = "$output/${constellation.name}.constpack";
    } else {
      Directory(output).createSync();
      to = "$output/${constellation.name}.constpack";
    }
    archive.create(to);
    Map<dynamic, dynamic> details = {};
    details["name"] = constellation.name;
    details["hostname"] = Arceus.userIndex.getHostUser().name;
    details["version"] = Updater.currentVersion;
    details["date"] = DateTime.now().toString();
    final detailsJson = jsonEncode(details);
    archive.addArchiveFile(
      ArchiveFile(
        "pack",
        detailsJson.length,
        detailsJson.codeUnits,
      ),
    );
    for (FileSystemEntity entity
        in Directory(constellation.constellationPath).listSync()) {
      if (entity is File) {
        if (!(entity.path.endsWith(".star") ||
            entity.path.endsWith("starmap"))) {
          continue;
        }
        archive.addFile(entity);
      }
    }
    archive.closeSync();
    return ConstellationPackage(to);
  }

  Map<String, dynamic> _getDetails() {
    Archive archive = _getArchive();
    ArchiveFile? file = archive.findFile("pack");
    String content = utf8.decode(file!.content);
    archive.clearSync();
    file.closeSync();
    return jsonDecode(content);
  }

  /// # void unpack(String toPath)
  /// ## Unpacks the constellation package to the given path.
  /// This is used when importing a constellation package into the a directory.
  void unpack(String toPath) {
    Archive archive = _getArchive();
    for (ArchiveFile file in archive.files) {
      if (file.isFile && file.name != "pack") {
        File("$toPath/.constellation/${file.name}")
            .writeAsBytesSync(file.content);
      }
    }
    archive.clearSync();
  }
}

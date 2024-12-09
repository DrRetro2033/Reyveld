import 'dart:io';
import 'package:ansix/ansix.dart';

import '../uuid.dart';

/// # `class` UserIndex
/// ## A class that represents a user index.
/// The user index is a file that contains all the users in Arceus.
/// Right now, the index is unique to each constellation, however in the future, it will be shared across all constellations.
class UserIndex {
  static const AnsiGridTheme gridTheme = AnsiGridTheme(
      headerTextTheme: AnsiTextTheme(
          backgroundColor: AnsiColor.blueViolet,
          alignment: AnsiTextAlignment.center));
  final String filepath;
  File get file => File(filepath);
  UserIndex(this.filepath) {
    users = _load();
  }

  late List<User> users;

  List<List<Object?>> get rows {
    List<List<Object?>> rows = [];
    rows.add(<Object?>["#", "Name"]);
    for (User user in users) {
      rows.add(<Object?>[user.hash.toString(), user.name.toString()]);
    }
    return rows;
  }

  List<User> _load() {
    List<User> users = [];
    final file = File(filepath);
    if (file.existsSync()) {
      for (String line in file.readAsLinesSync()) {
        users.add(User.fromString(this, line));
      }
    }
    return users;
  }

  void _save() {
    file.createSync(recursive: true);
    file.writeAsStringSync("", mode: FileMode.writeOnly); // clear file
    for (User user in users) {
      file.writeAsStringSync("${user.toString()}\n", mode: FileMode.append);
    }
  }

  User getUser(String hash) {
    if (users.isEmpty) {
      throw Exception("No users found!");
    }
    return users.firstWhere((element) => element.hash == hash,
        orElse: getHostUser);
  }

  User getHostUser() {
    if (users.isEmpty) {
      createUser("host");
    }
    return users.first;
  }

  void createUsers(Iterable<String> names) {
    for (String name in names) {
      createUser(name);
    }
  }

  void createUser(String name) {
    if (users.any((element) => element.name == name)) {
      print("Not recommended to have two users with the same name.");
    }
    String? hash;
    for (int i = 0; i < 100; i++) {
      hash = User.generateUniqueUserHash();
      if (!users.any((element) => element.hash == hash)) {
        break;
      }
      hash = null;
    }
    if (hash == null) {
      throw Exception("Unable to generate a unique user hash.");
    }
    User user = User(this, name, hash);
    users.add(user);
    _save();
  }

  void displayUsers() {
    final AnsiGrid verticalGrid = AnsiGrid.fromRows(rows, theme: gridTheme);
    print(verticalGrid);
  }
}

class User {
  static const int _lengthOfHash = 8;
  UserIndex userIndex;
  String? _name;
  String get name => _name!;
  set name(String value) {
    _name = value;
    userIndex._save();
  }

  late String hash;
  User(this.userIndex, this._name, this.hash);

  @override
  String toString() {
    return "$hash$_name";
  }

  static String generateUniqueUserHash() {
    String hash = generateUUID();
    return hash.substring(0, _lengthOfHash);
  }

  factory User.fromString(UserIndex userIndex, String string) {
    String hash = string.substring(0, _lengthOfHash);
    String name = string.substring(_lengthOfHash);
    return User(userIndex, name, hash);
  }
}

import 'dart:io';

import '../uuid.dart';
import 'package:arceus/widget_system.dart';

/// # `class` UserIndex
/// ## A class that represents a user index.
/// The user index is a file that contains all the users in Arceus.
class UserIndex {
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
    List<User> tempUsers = [];
    final file = File(filepath);
    if (file.existsSync()) {
      for (String line in file.readAsLinesSync()) {
        tempUsers.add(User.fromString(this, line));
      }
    }
    return tempUsers;
  }

  void _save() {
    file.createSync(recursive: true);
    file.writeAsStringSync("", mode: FileMode.writeOnly); // clear file
    for (User user in users) {
      file.writeAsStringSync("${user.toString()}\n", mode: FileMode.append);
    }
  }

  bool doesUserHashExist(String hash) {
    return users.any((element) => element.hash == hash);
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
    String hash = generateUniqueHash(users.map((e) => e.hash).toSet(),
        length: User.lengthOfHash);
    User user = User(this, name, hash);
    users.add(user);
    _save();
  }

  void displayUsers() {
    for (User user in users) {
      print(user.badge);
    }
  }
}

class User {
  static const int lengthOfHash = 8;
  static const Set<String> _userColors = {
    "red",
    "green",
    "yellow",
    "darkturquoise",
    "aqua",
    "fuchia",
    "crimson",
    "coral",
    "orange",
    "beige",
  };
  UserIndex userIndex;
  String? _name;
  String get name => _name!;
  set name(String value) {
    _name = value;
    userIndex._save();
  }

  Badge get badge => Badge("👤$name", badgeColor: color);

  late String hash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  User(this.userIndex, this._name, this.hash);

  @override
  String toString() {
    return "$hash$_name";
  }

  String get color {
    return _userColors.elementAt(
        hash.runes.reduce((value, element) => value + element) %
            _userColors.length);
  }

  factory User.fromString(UserIndex userIndex, String string) {
    String hash = string.substring(0, lengthOfHash);
    String name = string.substring(lengthOfHash);
    return User(userIndex, name, hash);
  }
}

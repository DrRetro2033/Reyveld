import 'dart:io';
import 'package:ansix/ansix.dart';

import '../uuid.dart';
import 'package:arceus/widget_system.dart';

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
    final AnsiGrid verticalGrid = AnsiGrid.fromRows(rows, theme: gridTheme);
    print(verticalGrid);
  }
}

class User {
  static const int lengthOfHash = 8;
  static const Set<AnsiColor> _userColors = {
    AnsiColor.maroon,
    AnsiColor.green,
    AnsiColor.olive,
    AnsiColor.navy,
    AnsiColor.magenta,
    AnsiColor.teal,
    AnsiColor.silver,
    AnsiColor.grey,
    AnsiColor.red,
    AnsiColor.lime,
    AnsiColor.yellow,
    AnsiColor.blue,
    AnsiColor.fuchsia,
    AnsiColor.aqua,
    AnsiColor.white,
    AnsiColor.cadetBlue,
    AnsiColor.orange1,
    AnsiColor.orange2,
    AnsiColor.orange3,
    AnsiColor.orange4,
    AnsiColor.blueViolet,
    AnsiColor.cornflowerBlue,
    AnsiColor.gold1,
    AnsiColor.gold2,
    AnsiColor.gold3,
    AnsiColor.indianRed,
    AnsiColor.lightCoral,
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
  User(this.userIndex, this._name, this.hash);

  @override
  String toString() {
    return "$hash$_name";
  }

  AnsiColor get color {
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

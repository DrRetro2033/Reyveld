import 'dart:io';
import 'package:ansix/ansix.dart';

import '../uuid.dart';

class UserIndex {
  static const String filenameOfUserIndex = "userindex";
  static const AnsiGridTheme gridTheme = AnsiGridTheme(
      headerTextTheme: AnsiTextTheme(
          backgroundColor: AnsiColor.blueViolet,
          alignment: AnsiTextAlignment.center));
  String? filepath;
  UserIndex(String path) {
    filepath = "$path/$filenameOfUserIndex";
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
    final file = File(filepath!);
    if (file.existsSync()) {
      for (String line in file.readAsLinesSync()) {
        users.add(User.fromString(this, line));
      }
    }
    return users;
  }

  void _save() {
    final file = File(filepath!);
    file.createSync(recursive: true);
    file.writeAsStringSync("", mode: FileMode.writeOnly); // clear file
    for (User user in users) {
      file.writeAsStringSync("${user.toString()}\n", mode: FileMode.append);
    }
  }

  User getUser(String hash) {
    return users.firstWhere((element) => element.hash == hash);
  }

  User getHostUser() {
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
    print("Created user: ${user.name}");
  }

  void displayUsers() {
    final AnsiGrid verticalGrid = AnsiGrid.fromRows(rows, theme: gridTheme);
    print(verticalGrid);
  }
}

class User {
  static const int lengthOfHash = 8;
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
    return hash.substring(0, lengthOfHash);
  }

  factory User.fromString(UserIndex userIndex, String string) {
    String hash = string.substring(0, lengthOfHash);
    String name = string.substring(lengthOfHash);
    return User(userIndex, name, hash);
  }
}

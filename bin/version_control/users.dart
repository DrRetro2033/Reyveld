import 'dart:io';
import '../uuid.dart';

class UserIndex {
  static const String filenameOfUserIndex = "userindex";
  String? filepath;
  UserIndex(String path) {
    filepath = "$path/$filenameOfUserIndex";
  }

  List<User> get users => _load();

  List<User> _load() {
    List<User> users = [];
    final file = File(filepath!);
    if (file.existsSync()) {
      for (String line in file.readAsLinesSync()) {
        users.add(User.fromString(line));
      }
    }
    return users;
  }

  void _save(List<User> users) {
    final file = File(filepath!);
    file.createSync(recursive: true);
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
    List<User> x = users;
    if (x.any((element) => element.name == name)) {
      print("Not recommended to have two users with the same name.");
    }
    String? hash;
    for (int i = 0; i < 100; i++) {
      hash = User.generateUniqueUserHash();
      if (!x.any((element) => element.hash == hash)) {
        break;
      }
      hash = null;
    }
    if (hash == null) {
      throw Exception("Unable to generate a unique user hash.");
    }
    User user = User(name, hash);
    x.add(user);
    _save(x);
    print("Created user: ${user.name}");
  }
}

class User {
  static const int lengthOfHash = 8;
  String? name;
  late String hash;
  User(this.name, this.hash);

  @override
  String toString() {
    return "$hash$name";
  }

  static String generateUniqueUserHash() {
    String hash = generateUUID();
    return hash.substring(0, lengthOfHash);
  }

  factory User.fromString(String string) {
    String hash = string.substring(0, lengthOfHash);
    String name = string.substring(lengthOfHash);
    return User(name, hash);
  }
}

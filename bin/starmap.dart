import 'package:isar/isar.dart';

part 'starmap.g.dart';

@collection
class User {
  Id? id;
  late String name;

  @Backlink(to: 'user')
  final stars = IsarLinks<Star>();
}

@collection
class File {
  Id? id;

  @IndexType.hash
  late String filename;

  @Backlink(to: 'file')
  final stars = IsarLinks<Star>();
}

@collection
class Star {
  Id? id;

  late String name;
  late List<byte> data;
  final file = IsarLink<File>();
  final user = IsarLink<User>();

  final next = IsarLinks<Star>();

  @Backlink(to: 'next')
  final prev = IsarLinks<Star>();
}

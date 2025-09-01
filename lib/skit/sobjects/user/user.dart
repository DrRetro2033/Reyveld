import 'package:reyveld/skit/sobject.dart';

part 'user.g.dart';
part 'user.creator.dart';
part 'user.interface.dart';

/// Repersents a user in a kit file.
/// A user can be created to associate a [SObject] with a specific user, allowing for multi-user support.
@SGen("user")
class SUser extends SRoot {
  String get name => get("name") ?? "";
  set name(String value) => set("name", value);

  SUser(super._node);

  @override
  Future<SIndent<SRoot>> newIndent() {
    // TODO: implement newIndent
    throw UnimplementedError();
  }
}

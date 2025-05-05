import 'package:arceus/skit/sobject.dart';

part 'user.g.dart';

/// Repersents a user in a kit file.
/// A user can be created to associate a [SObject] with a specific user, allowing for multi-user support.
@SGen("user")
class SUser extends SRoot {
  String get name => get("name") ?? "";
  set name(String value) => set("name", value);

  SUser(super.kit, super.node);
}

class SUserCreator extends SRootCreator<SUser> {
  final String name;

  SUserCreator(this.name);

  @override
  get creator => (builder) {
        builder.attribute("name", name);
      };
}

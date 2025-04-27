import 'package:arceus/skit/sobject.dart';

part 'user.g.dart';

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

part of 'user.dart';

/// Represents an user creator in a kit file.
class SUserCreator extends SCreator<SUser> {
  final String name;
  final String id;

  SUserCreator(this.name, this.id);

  @override
  build(builder) {
    builder.attribute("name", name);
    builder.attribute("hash", id);
  }
}

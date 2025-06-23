part of 'user.dart';

/// Represents an user creator in a kit file.
class SUserCreator extends SCreator<SUser> {
  final String name;
  final String hash;

  SUserCreator(this.name, this.hash);

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.attribute("hash", hash);
      };
}

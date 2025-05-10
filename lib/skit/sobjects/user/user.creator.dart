part of 'user.dart';

class SUserCreator extends SCreator<SUser> {
  final String name;

  SUserCreator(this.name);

  @override
  get creator => (builder) {
        builder.attribute("name", name);
      };
}

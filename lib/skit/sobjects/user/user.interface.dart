part of 'user.dart';

class UserInterface extends SInterface<SUser> {
  @override
  get className => "SUser";

  @override
  get classDescription => "Represents a user in a kit file.";

  @override
  get exports => {
        LEntry(
            name: "name",
            descr: "Sets and gets the name of the user.",
            args: const {
              LArg<String>(
                  name: "name",
                  descr: "The new name of the user.",
                  kind: ArgKind.optionalPositional),
            },
            returnType: String,
            () => object!.name),
      };
}

part of 'authveld.dart';

class AuthVeldInterface extends SInterface<AuthVeld> {
  @override
  String get className => "AuthVeld";

  @override
  get statics => {
        LEntry(
            name: "authorize",
            descr:
                """Makes an authorization request with AuthVeld. Will open the user's browser to the authorization page, 
                where they will decide if they allow the application to access Arceus with the given permissions.""",
            args: {
              "name": LArg<String>(descr: "The name of the application."),
              "permissions": LArg<List>(
                  descr: "The permissions to request.",
                  docTypeOverride: "SPolicy[]"),
            },
            returnType: String,
            isAsync: true,
            (String name, List permissions) async =>
                await AuthVeld.getAuthorization(
                    name, permissions.whereType<SPolicy>().toList())),
      };
}

part of 'authveld.dart';

class AuthVeldInterface extends SInterface<AuthVeld> {
  @override
  String get className => "AuthVeld";

  @override
  get staticDescription =>
      """AuthVeld is a service that allows users to authorize applications to access Reyveld.
This interface provides methods to make authorization requests and load certificates. These certificates describe what an application can and cannot do inside of the constrained environment of Reyveld.""";
  @override
  get statics => {
        LEntry(
            name: "authorize",
            descr: """Makes an authorization request with AuthVeld.
Will open the user's browser to the authorization page, where they will decide if they allow the application to access Reyveld with the given permissions.""",
            args: {
              LArg<String>(name: "name", descr: "The name of the application."),
              LArg<List>(
                  name: "permissions",
                  descr: "The permissions to request.",
                  docTypeOverride: "SPolicy[]"),
            },
            returnType: String,
            isAsync: true,
            (String name, List permissions) async =>
                await AuthVeld.getAuthorization(
                    name, permissions.whereType<SPolicy>().toList())),
        LEntry(
            name: "loadCertificate",
            descr: "Loads an application's certificate, using a token.",
            args: const {
              LArg<String>(
                  name: "token",
                  descr: "The token to use to load the certificate."),
            },
            isAsync: true,
            passLua: true, (Lua lua, String token) async {
          lua.certificate = await AuthVeld.loadCertificate(token);
          Reyveld.talker.log("Loaded certificate: ${lua.certificate!.hash}");
        }),
        LEntry(
            name: "currentPolicies",
            descr:
                "The policies of the currently loaded certificate. Will return null if no certificate has been loaded.",
            returnType: List,
            passLua: true, (Lua lua) {
          if (lua.certificate == null) return null;
          return lua.certificate!.policies;
        }),
      };
}

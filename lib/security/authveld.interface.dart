part of 'authveld.dart';

class AuthVeldInterface extends SInterface<AuthVeld> {
  @override
  String get className => "AuthVeld";

  @override
  get classDescription =>
      """AuthVeld is a service that allows users to authorize applications to access Reyveld.

This interface provides methods to make authorization requests and load certificates. 

Certificates describe what an application can and cannot do inside of the constrained nevironment of Reyveld.""";
  @override
  get statics => {
        LEntry(
            name: "authorize",
            descr: """Makes an authorization request with AuthVeld.
            
Will open the user's browser to the authorization page, where they will decide if they allow the application to access Reyveld with the given permissions.""",
            args: {
              LArg<String>(name: "name", descr: "The name of the application."),
              LArg<String>(
                  name: "reasoning",
                  descr: "The reasoning behind the request."),
              LArg<List>(
                  name: "permissions",
                  descr: "The permissions to request.",
                  docTypeOverride: "SPolicy[]"),
            },
            returnType: String,
            isAsync: true,
            (String name, String reasoning, List permissions) async =>
                await AuthVeld.getAuthorization(name, reasoning,
                    permissions.whereType<SPolicy>().toList())),
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
          if (lua.certificate == null) {
            Reyveld.talker.warning("No certificate with that token was found!");
          } else if (!lua.certificate!.authorized) {
            Reyveld.talker.warning("Certificate is not currently authorized!");
          }
          Reyveld.talker.verbose(
              "Loaded certificate for ${lua.certificate!.appname}: ${lua.certificate!.id}");
        }),
        LEntry(
            name: "hasCertificate",
            descr:
                "Checks if the certificate exists in AuthVeld. Should be checked before trying to load a certificate, as the user might have deleted it.",
            args: const {
              LArg<String>(
                  name: "token",
                  descr: "The token to use to load the certificate."),
            },
            returnType: bool,
            isAsync: true,
            (String token) async => await AuthVeld.hasCertificate(token)),
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

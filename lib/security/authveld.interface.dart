part of 'authveld.dart';

class AuthVeldInterface extends SInterface<AuthVeld> {
  @override
  String get className => "AuthVeld";

  @override
  get classDescription =>
      """AuthVeld is a service that allows users to authorize applications to access Reyveld.

This interface provides methods to make authorization requests and load contracts. 

Contracts describe what an application can and cannot do inside of the constrained environment of Reyveld.""";
  @override
  get statics => {
        LEntry(
            name: "newContract",
            descr:
                """Makes an authorization request with AuthVeld to create a new contract.
            
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
            (String name, List permissions) async => await AuthVeld.newContract(
                name, permissions.whereType<SPolicy>().toList())),
        LEntry(
            name: "deleteContract",
            descr: "Deletes an application's contract, using a token.",
            args: const {
              LArg<String>(
                  name: "token",
                  descr: "The token to use to delete the contract."),
            },
            isAsync: true,
            (String token) async => await AuthVeld.deleteContract(token)),
        LEntry(
            name: "loadContract",
            descr: "Loads an application's contract, using a token.",
            args: const {
              LArg<String>(
                  name: "token",
                  descr: "The token to use to load the contract."),
            },
            isAsync: true,
            passLua: true, (Lua lua, String token) async {
          lua.contract = await AuthVeld.getContract(token);
          if (lua.contract == null) {
            Reyveld.talker.warning("No contract with that token was found!");
          } else if (!lua.contract!.authorized) {
            Reyveld.talker.warning("Contract is not currently authorized!");
          }
          Reyveld.talker.verbose(
              "Loaded contract for ${lua.contract!.appname}: ${lua.contract!.id}");
        }),
        LEntry(
            name: "hasContract",
            descr:
                "Checks if the contract exists in AuthVeld. Should be checked before trying to load a contract, as the user might have deleted it.",
            args: const {
              LArg<String>(
                  name: "token",
                  descr: "The token to use to load the contract."),
            },
            returnType: bool,
            isAsync: true,
            (String token) async => await AuthVeld.hasContract(token)),
        LEntry(
            name: "currentPolicies",
            descr:
                "The policies of the currently loaded certificate. Will return null if no certificate has been loaded.",
            returnType: List,
            passLua: true, (Lua lua) {
          if (lua.contract == null) return null;
          return lua.contract!.policies;
        }),
        LEntry(
            name: "requiresUpdate",
            descr: "Checks if a certificate needs to be updated.",
            args: const {
              LArg<String>(
                  name: "token",
                  descr: "The token to use to load the contract."),
              LArg<List>(
                  name: "policies",
                  descr: "The policies to check.",
                  docTypeOverride: "SPolicy[]"),
            },
            returnType: bool,
            isAsync: true,
            (String token, List policies) async =>
                await AuthVeld.requiresUpdate(
                    token, policies.whereType<SPolicy>().toList())),
      };
}

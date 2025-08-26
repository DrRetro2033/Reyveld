import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/event.dart';
import 'package:arceus/scripting/lua.dart';
import 'package:arceus/scripting/sinterface.dart';
import 'package:talker/talker.dart';

/// This is the socket interface.
/// This can be used from Lua to send data through the web socket,
/// so the external client can know what the script is doing at a given time.
class SessionInterface extends SInterface<WebSocket> {
  @override
  String get className => "Session";

  @override
  String get classDescription =>
      "Send data through the web socket of the current session during script execution.";

  @override
  get exports => {
        LField<String>(
            name: "os",
            descr:
                "The operating system of the server. (\"${Platform.operatingSystem}\")",
            Platform.operatingSystem),
        LEntry(
            name: "send",
            descr: "Send data through the web socket.",
            args: {
              LArg<Object>(
                  name: "data",
                  descr: "The data to send through the web socket."),
              LArg<String>(
                  name: "message",
                  descr: "The message with the data to send with the data.",
                  kind: ArgKind.optionalNamed),
            },
            passLua: true, (Lua lua, Object data, {String message = ""}) {
          object!.add(SocketEvent.data(lua.processId!, data).toString());
        }),
        LEntry(
            name: "talk",
            descr: "Returns the logger (aka. talker) of this session.",
            returnType: Talker,
            () => Arceus.talker)
      };
}

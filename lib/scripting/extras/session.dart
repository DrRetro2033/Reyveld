import 'dart:io';

import 'package:reyveld/reyveld.dart';
import 'package:reyveld/event.dart';
import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/scripting/sinterface.dart';
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
          object!.add(SocketEvent.data(data, pid: lua.processId).toString());
        }),
        LEntry(
            name: "pid",
            descr:
                "Set and returns the process id of this current session. Empty by default.",
            args: const {
              LArg<String>(
                  name: "processId",
                  descr: "The process id to set.",
                  kind: ArgKind.optionalPositional),
            },
            passLua: true, (Lua lua, [String? processId]) {
          if (processId != null) {
            lua.processId = processId;
          }
          return lua.processId;
        }),
        LEntry(
            name: "talk",
            descr: "Returns the logger (aka. talker) of this session.",
            returnType: Talker,
            () => Reyveld.talker)
      };
}

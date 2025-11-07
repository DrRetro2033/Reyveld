import 'dart:io';

import 'package:lua_dardo_async/lua.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/event.dart';
import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/scripting/sinterface.dart';
import 'package:talker/talker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This is the socket interface.
/// This can be used from Lua to send data through the web socket,
/// so the external client can know what the script is doing at a given time.
class SessionInterface extends SInterface<WebSocketChannel> {
  @override
  String get className => "Session";

  @override
  String get classDescription =>
      """Contains methods for the current session with Reyveld. 
This can be used to send data through the web socket, log messages, etc.""";

  @override
  get statics => {
        LEntry(
            name: "os",
            descr:
                "The operating system of the server. (\"${Platform.operatingSystem}\")",
            returnType: String,
            () => Platform.operatingSystem),
        LEntry(
            name: "send",
            descr:
                "Send data through the web socket (or console if running in a terminal).",
            args: {
              LArg<Object>(
                  name: "data",
                  descr: "The data to send through the web socket."),
              LArg<String>(
                  name: "message",
                  descr: "The message with the data to send with the data.",
                  kind: ArgKind.optionalNamed),
            },
            passLua: true,
            passState: true, (Lua lua, LuaState state, Object data,
                {String message = ""}) {
          if (lua.socket == null) {
            Reyveld.printToConsole(data);
            return;
          } else if (lua.socket!.closeCode != null) {
            return;
          }
          lua.socket!.sink.add(
              SocketEvent.data(data, pid: lua.getPID(state) ?? "").toString());
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
            passLua: true,
            passState: true, (Lua lua, LuaState state, [String? processId]) {
          if (processId != null) {
            lua.setPID(state, processId);
          }
          return lua.getPID(state);
        }),
        LEntry(
            name: "talk",
            descr: "Returns the logger (aka. talker) of this session.",
            returnType: Talker,
            () => Reyveld.talker),
        LEntry(
            name: "error",
            descr:
                "This function will always throw an error. Used for testing lua's tracing.",
            () => throw Exception("This is an test error.")),
      };
}

import 'dart:convert';
import 'dart:io';

import 'package:arceus/scripting/sinterface.dart';

/// This is the socket interface.
/// This can be used from Lua to send data through the web socket,
/// so the external client can know what the script is doing at a given time.
class SocketInterface extends SInterface<WebSocket> {
  @override
  String get className => "Socket";

  @override
  String get classDescription =>
      "Send data through the current web socket during script execution.";

  @override
  get exports => {
        LEntry(
            name: "send",
            descr: "Send data through the web socket.",
            args: {
              "data": LArg<Object>(
                  descr: "The data to send through the web socket."),
              "message": LArg<String>(
                descr: "The message with the data to send with the data.",
                positional: false,
                required: false,
              ),
            },
            (Object data, {String message = ""}) => object!.add(jsonEncode({
                  "message": message,
                  "timesent": DateTime.now().toIso8601String(),
                  "data": data,
                }))),
      };
}

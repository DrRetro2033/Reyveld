import 'dart:async';

import 'package:arceus/scripting/lua.dart';
import 'package:arceus/scripting/sinterface.dart';
import 'package:async/async.dart';

class StreamInterface extends SInterface<Stream> {
  StreamInterface();

  @override
  get className => "Stream";

  @override
  get classDescription =>
      "A stream of objects. Always make sure the stream finishes before ending the script.";

  @override
  get exports => {
        LEntry(
            name: "complete",
            descr: "Completes the stream, with the given functions.",
            isAsync: true,
            args: {
              "onData": LArg<LuaFuncRef>(
                  descr: "The function to call when data is received.",
                  docTypeOverride: "fun(data: any):nil",
                  required: false,
                  positional: false),
            }, ({LuaFuncRef? onData}) async {
          final StreamQueue queue = StreamQueue(object!);
          while (await queue.hasNext) {
            final data = await queue.next;
            if (data == Exception) throw data;
            if (data != null && onData != null) onData.call([data]);
          }
          await onData!.unregister();
        }),
      };
}

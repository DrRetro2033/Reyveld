import 'dart:async';

import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/scripting/sinterface.dart';
import 'package:rxdart/rxdart.dart';

class StreamInterface extends SInterface<Stream> {
  StreamInterface();

  @override
  get className => "Stream";

  @override
  get classDescription =>
      "A stream of objects. Always make sure the stream finishes before ending the script.";

  @override
  get statics => {
        LEntry(
            name: "fromIterable",
            descr: "Creates a stream from an iterable.",
            args: const {
              LArg<List>(
                  name: "iterable",
                  descr: "The iterable to create the stream from.")
            },
            returnType: Stream, (List iterable) {
          return Stream.fromIterable(iterable);
        })
      };

  @override
  get exports => {
        LEntry(
            name: "complete",
            descr: "Completes the stream, with the given functions.",
            isAsync: true,
            args: const {
              LArg<LuaFuncRef>(
                  name: "onData",
                  descr: "The function to call when data is received.",
                  docTypeOverride: "fun(data: any):nil",
                  kind: ArgKind.optionalNamed),
            }, ({LuaFuncRef? onData}) async {
          await for (final data in object!) {
            if (onData != null) await onData.call([data]);
          }
          await onData!.unregister();
        }),
        LEntry(
          name: "merge",
          descr:
              "Merge this stream with another stream. Both streams should be of the same type.",
          args: const {
            LArg<Stream>(
              name: "other",
              descr: "The other stream to merge with.",
            ),
          },
          returnType: Stream,
          (Stream other) => object!.mergeWith([other]),
        ),
        LEntry(
            name: "transform",
            descr: "Transforms data in a stream with a function.",
            args: const {
              LArg<LuaFuncRef>(
                  name: "method",
                  descr: "The function to call on each data event.",
                  docTypeOverride: "fun(data: any):any",
                  kind: ArgKind.requiredPositional)
            },
            returnType: Stream,
            (LuaFuncRef method) =>
                object!.asyncMap((e) async => await method.call([e]))),
      };
}

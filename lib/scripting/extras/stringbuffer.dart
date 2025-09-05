import 'package:reyveld/scripting/sinterface.dart';

class StringBufferInterface extends SInterface<StringBuffer> {
  @override
  get className => "StringBuffer";

  @override
  String get classDescription => "Represents a mutable sequence of characters.";

  @override
  get statics => {
        LEntry(
            name: "new",
            descr: "Creates a new string buffer.",
            args: const {
              LArg<String>(
                  name: "string",
                  descr: "The initial string.",
                  kind: ArgKind.optionalPositional)
            },
            returnType: StringBuffer,
            ([String? string]) => StringBuffer(string ?? "")),
      };

  @override
  get exports => {
        LEntry(
          name: "writeCharCode",
          descr: "Writes a character code to the buffer.",
          args: const {
            LArg<int>(
                name: "byte",
                descr: "The character code to write to the buffer.")
          },
          (int string) => object!.writeCharCode(string),
        ),
        LEntry(
            name: "write",
            descr: "Writes a string to the buffer, without a newline.",
            args: const {
              LArg<String>(
                  name: "string", descr: "The string to write to the buffer.")
            },
            (String string) => object!.write(string)),
        LEntry(
            name: "writeln",
            descr: "Writes a string to the buffer, with a newline.",
            args: const {
              LArg<String>(
                  name: "string", descr: "The string to write to the buffer.")
            },
            (String string) => object!.writeln(string)),
        LEntry(
            name: "length",
            descr: "The length of the buffer.",
            returnType: int,
            () => object!.length),
        LEntry(
            name: "clear", descr: "Clears the buffer.", () => object!.clear()),
        LEntry(
            name: "toString",
            descr: "Returns the string representation of this buffer.",
            returnType: String,
            () => object!.toString()),
      };
}

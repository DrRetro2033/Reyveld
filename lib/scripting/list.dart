import 'package:arceus/scripting/lua.dart';
import 'package:arceus/scripting/sinterface.dart';

class ListInterface extends SInterface<List> {
  @override
  get className => "List";

  @override
  get classDescription => "A list of objects.";

  @override
  get exports => {
        LEntry(
            name: "add",
            descr: "Adds an object to the list.",
            args: const {
              "object": LArg<Object>(
                descr: "The object to add.",
              )
            },
            (Object value) => object!.add(value)),
        LEntry(
            name: "remove",
            descr: "Removes an object from the list.",
            args: const {
              "object": LArg<Object>(
                descr: "The object to remove.",
              )
            },
            (Object value) => object!.remove(value)),
        LEntry(
            name: "pop",
            descr: "Removes the last object from the list and returns it.",
            () => object!.removeLast()),
        LEntry(
            name: "length",
            descr: "Returns the length of the list.",
            returnType: int,
            () => object!.length),
        LEntry(
            name: "first",
            descr: "Returns the first object in the list.",
            returnType: Object,
            () => object!.first),
        LEntry(
            name: "last",
            descr: "Returns the last object in the list.",
            returnType: Object,
            () => object!.last),
        LEntry(
            name: "contains",
            descr: "Returns true if the list contains the object.",
            args: const {
              "object": LArg<Object>(
                descr: "The object to check for.",
              )
            },
            returnType: bool,
            (Object value) => object!.contains(value)),
        LEntry(
            name: "get",
            descr: "Returns the object at the given index.",
            args: const {
              "index": LArg<int>(
                descr: "The index to get.",
              )
            },
            returnType: Object,
            (int index) => object![index]),
        LEntry(
            name: "single",
            descr:
                "Returns the only object in the list. Will throw an error if the list is empty or has more than one object.",
            returnType: Object,
            () => object!.single),
        LEntry(
          name: "forEach",
          descr: "Runs a function for each object in the list.",
          args: const {
            "func": LArg<LuaFuncRef>(
              descr: "The function to run.",
            )
          },
          (LuaFuncRef function) async {
            for (var e in object!) {
              await function.call([e]);
            }
            await function.unregister();
          },
        )
      };
}

import 'package:arceus/scripting/lua.dart';
import 'package:arceus/scripting/sinterface.dart';

class ListInterface extends SInterface<List> {
  @override
  get className => "List";

  @override
  get classDescription => "A list of objects.";

  @override
  get statics => {
        LEntry(
            name: "new",
            descr: "Creates a new list.",
            returnType: List,
            () => [])
      };

  @override
  get exports => {
        LEntry(
            name: "add",
            descr: "Adds an object to the list.",
            args: const {
              LArg<Object>(
                name: "object",
                descr: "The object to add.",
              )
            },
            returnType: List, (Object value) {
          object!.add(value);
          return object!;
        }),
        LEntry(
            name: "remove",
            descr: "Removes an object from the list.",
            args: const {
              LArg<Object>(
                name: "object",
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
              LArg<Object>(
                name: "object",
                descr: "The object to check for.",
              )
            },
            returnType: bool,
            (Object value) => object!.contains(value)),
        LEntry(
            name: "get",
            descr: "Returns the object at the given index.",
            args: const {
              LArg<int>(
                name: "index",
                descr: "The index to get.",
              )
            },
            returnType: Object,
            (int index) => object![index]),
        LEntry(
          name: "forEach",
          descr: "Runs a function for each object in the list.",
          args: const {
            LArg<LuaFuncRef>(
                name: "function",
                descr: "The function to run.",
                docTypeOverride: "fun(object: any):nil")
          },
          (LuaFuncRef function) async {
            for (var e in object!) {
              await function.call([e]);
            }
            await function.unregister();
          },
        ),
        LEntry(
          name: "firstWhere",
          descr:
              "Returns the first object in the list that passes the given function, or null if none match.",
          args: const {
            LArg<LuaFuncRef>(
                name: "check",
                descr: "The function to check.",
                docTypeOverride: "fun(object: any):boolean")
          },
          returnType: Object,
          returnNullable: true,
          (LuaFuncRef function) async {
            for (var e in object!) {
              if (await function.call([e]) == true) {
                return e;
              }
            }
            return null;
          },
        ),
        LEntry(
          name: "lastWhere",
          descr:
              "Returns the last object in the list that passes the given function, or null if none match.",
          args: const {
            LArg<LuaFuncRef>(
                name: "check",
                descr: "The function to check.",
                docTypeOverride: "fun(object: any):boolean"),
          },
          returnType: Object,
          returnNullable: true,
          (LuaFuncRef function) async {
            for (var e in object!.reversed) {
              if (await function.call([e]) == true) {
                return e;
              }
            }
            return null;
          },
        ),
        LEntry(
            name: "where",
            descr: "Returns a filtered copy of the list.",
            args: const {
              LArg<LuaFuncRef>(
                  name: "check",
                  descr: "The function to check.",
                  docTypeOverride: "fun(object: any):boolean")
            },
            returnType: List, (LuaFuncRef function) async {
          List filtered = [];
          for (var e in object!) {
            if (await function.call([e]) == true) {
              filtered.add(e);
            }
          }
          return filtered;
        }),
        LEntry(
            name: "reversed",
            descr: "Returns a reversed copy of the list.",
            returnType: List,
            () => object!.reversed.toList()),
      };
}

import 'package:arceus/scripting/sinterface.dart';

class ListInterface extends SInterface<List> {
  @override
  get className => "List";

  @override
  get classDescription => "A list of objects.";

  @override
  get exports => {
        "add": (
          "Adds an object to the list.",
          {"object": ("The object to add.", type: Object, isRequired: true)},
          null,
          (Object value) => object!.add(value)
        ),
        "remove": (
          "Removes an object from the list.",
          {"object": ("The object to remove.", type: Object, isRequired: true)},
          null,
          (Object value) => object!.remove(value)
        ),
        "pop": (
          "Removes the last object from the list and returns it.",
          {},
          null,
          () => object!.removeLast()
        ),
        "length": (
          "Returns the length of the list.",
          {},
          int,
          () => object!.length
        ),
        "first": (
          "Returns the first object in the list.",
          {},
          Object,
          () => object!.first
        ),
        "last": (
          "Returns the last object in the list.",
          {},
          Object,
          () => object!.last
        ),
        "contains": (
          "Returns true if the list contains the object.",
          {
            "object": (
              "The object to check for.",
              type: Object,
              isRequired: true
            )
          },
          bool,
          (Object value) => object!.contains(value)
        ),
        "get": (
          "Returns the object at the given index.",
          {"index": ("The index to get.", type: int, isRequired: true)},
          Object,
          (int index) => object![index]
        )
      };
}

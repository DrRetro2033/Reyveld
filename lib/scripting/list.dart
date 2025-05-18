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
          const {
            "object": (
              "The object to add.",
              type: Object,
              cast: typeCheck<Object>,
              isRequired: true
            )
          },
          null,
          false,
          (Object value) => object!.add(value)
        ),
        "remove": (
          "Removes an object from the list.",
          const {
            "object": (
              "The object to remove.",
              type: Object,
              cast: typeCheck<Object>,
              isRequired: true
            )
          },
          null,
          false,
          (Object value) => object!.remove(value)
        ),
        "pop": (
          "Removes the last object from the list and returns it.",
          const {},
          null,
          false,
          () => object!.removeLast()
        ),
        "length": (
          "Returns the length of the list.",
          const {},
          int,
          false,
          () => object!.length
        ),
        "first": (
          "Returns the first object in the list.",
          const {},
          Object,
          false,
          () => object!.first
        ),
        "last": (
          "Returns the last object in the list.",
          const {},
          Object,
          false,
          () => object!.last
        ),
        "contains": (
          "Returns true if the list contains the object.",
          const {
            "object": (
              "The object to check for.",
              type: Object,
              cast: typeCheck<Object>,
              isRequired: true
            )
          },
          bool,
          false,
          (Object value) => object!.contains(value)
        ),
        "get": (
          "Returns the object at the given index.",
          const {
            "index": (
              "The index to get.",
              type: int,
              cast: typeCheck<int>,
              isRequired: true
            )
          },
          Object,
          false,
          (int index) => object![index]
        ),
        "single": (
          "Returns the only object in the list. Will throw an error if the list is empty or has more than one object.",
          const {},
          Object,
          false,
          () => object!.single
        )
      };
}

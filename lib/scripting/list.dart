import 'package:arceus/scripting/sinterface.dart';

class ListInterface extends SInterface<List> {
  @override
  get className => "List";

  @override
  get description => "A list of objects.";

  @override
  get exports => {
        "add": (
          "Adds an object to the list.",
          {"object": ("The object to add.", Object, true)},
          null,
          (state) {
            final value = state.getFromTop();
            object!.add(value);
          }
        ),
        "remove": (
          "Removes an object from the list.",
          {"object": ("The object to remove.", Object, true)},
          null,
          (state) {
            final value = state.getFromTop();
            object!.remove(value);
          }
        ),
        "pop": (
          "Removes the last object from the list and returns it.",
          {},
          null,
          (state) => object!.removeLast()
        ),
        "length": (
          "Returns the length of the list.",
          {},
          int,
          (state) => object!.length
        ),
        "first": (
          "Returns the first object in the list.",
          {},
          Object,
          (state) => object!.first
        ),
        "last": (
          "Returns the last object in the list.",
          {},
          Object,
          (state) => object!.last
        ),
        "contains": (
          "Returns true if the list contains the object.",
          {"object": ("The object to check for.", Object, true)},
          bool,
          (state) => object!.contains(state.getFromTop())
        ),
      };
}

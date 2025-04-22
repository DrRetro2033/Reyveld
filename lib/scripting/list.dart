import 'package:arceus/scripting/sinterface.dart';

class ListInterface extends SInterface<List> {
  @override
  get className => "List";

  @override
  get description => "A list of objects.";

  @override
  get exports => {
        "add": (state) {
          final value = state.getFromTop();
          object!.add(value);
        },
        "remove": (state) {
          final value = state.getFromTop();
          object!.remove(value);
        },
        "pop": (state) => object!.removeLast(),
        "length": (state) => object!.length,
        "first": (state) => object!.first,
        "last": (state) => object!.last,
        "contains": (state) => object!.contains(state.getFromTop()),
      };
}

part of 'sobject.dart';

/// The interface for [SObject]
final class SObjectInterface extends SInterface<SObject> {
  @override
  get className => "SObject";

  @override
  get classDescription => """
A base class for all objects in the kit.
""";

  @override
  get exports => {
        "addChild": (
          "Adds a child SObject to the xml node.",
          const {
            "child": (
              "The child SObject to add.",
              type: SObject,
              cast: typeCheck<SObject>,
              isRequired: true
            )
          },
          null,
          false,
          (SObject child) => object!.addChild(child),
        ),
        "removeChild": (
          "Removes a child SObject from the xml node.",
          const {
            "child": (
              "The child SObject to remove.",
              type: SObject,
              cast: typeCheck<SObject>,
              isRequired: true
            )
          },
          null,
          false,
          (SObject child) => object!.removeChild(child),
        ),
        "getChild": (
          """
Returns a child of the SObject, with the specific type.

If filter is not provided, then it will return the first child of the sobject.

If filter is provided, then it will return the first child that matches the filter.

Filter Options:
- tag - A tag that represents the type of the child. To find the tag of a SObject type, see [SObject.tag](lua:SObject.tag).
- attrbs - A map of attributes to filter by. It will only return the first child that matches the attributes in the map.

""",
          {
            "filter": const (
              "A map to filter the children by.",
              type: Map,
              cast: typeCheck<Map>,
              isRequired: false
            )
          },
          SObject,
          false,
          ([Map<dynamic, dynamic>? filter]) {
            if (filter == null) return object!.getChild<SObject>();
            final type = filter.containsKey("tag") ? filter["tag"] : null;
            final attributes =
                filter.containsKey("attrbs") ? filter["attrbs"] : null;
            return object!.getChild<SObject>(
              filter: (e) {
                if (type != null) {
                  if (e.tag != type) {
                    return false;
                  }
                }
                for (final key in attributes.keys) {
                  if (e.get(key) != attributes[key]) {
                    return false;
                  }
                }
                return true;
              },
            );
          }
        ),
        "getChildren": (
          "Returns a list of all the children of the SObject.",
          {},
          List,
          false,
          () => object!.getChildren<SObject>,
        ),
        "getParent": (
          "Returns the parent of the SObject.",
          {},
          SObject,
          false,
          () => object!.getParent<SObject>,
        ),
        "getDescendants": (
          "Returns a list of all the descendants of the SObject.",
          {},
          List,
          false,
          () => object!.getDescendants<SObject>,
        ),
        "getAncestors": (
          "Returns a list of all the ancestors of the SObject.",
          {},
          List,
          false,
          () => object!.getAncestors<SObject>,
        ),
        "getSiblingAbove": (
          "Returns the sibling above the SObject.",
          {},
          SObject,
          false,
          () => object!.getSiblingAbove<SObject>(),
        ),
        "getSiblingBelow": (
          "Returns the sibling below the SObject.",
          {},
          SObject,
          false,
          () => object!.getSiblingBelow<SObject>,
        ),
      };
}

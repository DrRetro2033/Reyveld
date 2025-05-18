part of 'sobject.dart';

LuaEntrypoint tagEntry(SFactory factory) => (
      "Gets the xml tag of this type. (\"${factory.tag}\")",
      const {},
      String,
      false,
      () => factory.tag
    );

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
//         "getChild": (
//           """
// Returns a child of the SObject, with the specific type.

// If filter is not provided, then it will return the first child of the sobject.

// If filter is provided, then it will return the first child that matches the filter.

// Filter Options:
// - tag - A tag that represents the type of the child. To find the tag of a SObject type, see [SObject.tag](lua:SObject.tag).
// - attrbs - A map of attributes to filter by. It will only return the first child that matches the attributes in the map.

// """,
//           {
//             "filter": const (
//               "A map to filter the children by.",
//               type: Map,
//               cast: typeCheck<Map>,
//               isRequired: false
//             )
//           },
//           SObject,
//           false,
//           ([Map<dynamic, dynamic>? filter]) {
//             if (filter == null) return object!.getChild<SObject>();
//             final type = filter.containsKey("tag") ? filter["tag"] : null;
//             final attributes =
//                 filter.containsKey("attrbs") ? filter["attrbs"] : null;
//             return object!.getChild<SObject>(
//               filter: (e) {
//                 if (type != null) {
//                   if (e.tag != type) {
//                     return false;
//                   }
//                 }
//                 for (final key in attributes.keys) {
//                   if (e.get(key) != attributes[key]) {
//                     return false;
//                   }
//                 }
//                 return true;
//               },
//             );
//           }
//         ),
        "getChildren": (
          "Returns a list of all the children of the SObject.",
          {},
          List<SObject>,
          false,
          () => object!.getChildren().nonNulls.toList(),
        ),
        "getParent": (
          "Returns the parent of the SObject.",
          {},
          SObject,
          false,
          () => object!.getParent(),
        ),
        "getDescendants": (
          "Returns a list of all the descendants of the SObject.",
          {},
          List<SObject>,
          false,
          () => object!.getDescendants().nonNulls.toList(),
        ),
        "getAncestors": (
          "Returns a list of all the ancestors of the SObject.",
          {},
          List<SObject>,
          false,
          () => object!.getAncestors().nonNulls.toList(),
        ),
        "getSiblingAbove": (
          "Returns the sibling above the SObject.",
          {},
          SObject,
          false,
          () => object!.getSiblingAbove(),
        ),
        "getSiblingBelow": (
          "Returns the sibling below the SObject.",
          {},
          SObject,
          false,
          () => object!.getSiblingBelow(),
        ),
      };
}

final class SObjectListInterface extends SInterface<List<SObject>> {
  @override
  get className => "SObjectList";

  @override
  get classDescription => """
A list of SObjects.
""";

  @override
  get parent => ListInterface();

  @override
  get exports => {
        "withTag": (
          "Returns a list of SObjects that are of a specific tag.",
          const {
            "tag": (
              "The tag of SObject to filter by.",
              type: String,
              isRequired: true,
              cast: typeCheck<String>
            )
          },
          List<SObject>,
          false,
          (String tag) => object!.where((e) => e.tag == tag).toList(),
        )
      };
}

part of 'sobject.dart';

LEntry tagEntry(SFactory factory) => LEntry(
    name: "tag",
    descr: "Gets the xml tag of this type. (\"${factory.tag}\")",
    returnType: String,
    () => factory.tag);

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
        LEntry(
          name: "addChild",
          descr: "Adds a child SObject to the xml node.",
          args: const {
            "child": LArg<SObject>(
              descr: "The child SObject to add.",
            )
          },
          (SObject child) => object!.addChild(child),
        ),
        LEntry(
          name: "removeChild",
          descr: "Removes a child SObject from the xml node.",
          args: const {
            "child": LArg<SObject>(
              descr: "The child SObject to remove.",
            )
          },
          (SObject child) => object!.removeChild(child),
        ),
        LEntry(
          name: "getChild",
          descr: "Returns a child of the SObject.",
          args: const {
            "tag": LArg<String>(
              descr: "The tag of the child to get.",
              positional: false,
            ),
          },
          returnType: SObject,
          ({required String tag}) => object!.getChild<SObject>(
            filter: (p0) => p0.tag == tag,
          ),
        ),
        LEntry(
          name: "getChildren",
          descr: "Returns a list of all the children of the SObject.",
          returnType: List<SObject>,
          () => object!.getChildren().nonNulls.toList(),
        ),
        LEntry(
          name: "getParent",
          descr: "Returns the parent of the SObject.",
          returnType: SObject,
          () => object!.getParent(),
        ),
        LEntry(
          name: "getDescendants",
          descr: "Returns a list of all the descendants of the SObject.",
          returnType: List<SObject>,
          () => object!.getDescendants().nonNulls.toList(),
        ),
        LEntry(
          name: "getAncestors",
          descr: "Returns a list of all the ancestors of the SObject.",
          returnType: List<SObject>,
          () => object!.getAncestors().nonNulls.toList(),
        ),
        LEntry(
          name: "getSiblingAbove",
          descr: "Returns the sibling above the SObject.",
          returnType: SObject,
          () => object!.getSiblingAbove(),
        ),
        LEntry(
          name: "getSiblingBelow",
          descr: "Returns the sibling below the SObject.",
          returnType: SObject,
          () => object!.getSiblingBelow(),
        ),
        LEntry(
          name: "toJson",
          descr:
              "Returns a json representation of the SObject and its descendants.",
          returnType: Map,
          () => object!.toJson(),
        )
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
        LEntry(
          name: "withTag",
          descr: "Returns a list of SObjects that are of a specific tag.",
          args: const {
            "tag": LArg<String>(
              descr: "The tag of SObject to filter by.",
            )
          },
          returnType: List<SObject>,
          (String tag) => object!.where((e) => e.tag == tag).toList(),
        )
      };
}

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
          name: "tag",
          descr: "Gets the xml tag of this object.",
          returnType: String,
          () => object!.tag,
        ),
        LEntry(
          name: "addChild",
          descr: """Adds a child [SObject](lua://SObject) to the xml node.

If the child already has a parent, this will remove it from its current parent first before adding it to this one.""",
          args: const {
            LArg<SObject>(
              name: "child",
              descr: "The child SObject to add.",
            )
          },
          (SObject child) => object!.addChild(child),
        ),
        LEntry(
          name: "removeChild",
          descr: """Removes a child [SObject](lua://SObject) from this xml node.

This will not do anything if this SObject is not a parent of the child.""",
          args: const {
            LArg<SObject>(
              name: "child",
              descr: "The child SObject to remove.",
            )
          },
          (SObject child) => object!.removeChild(child),
        ),
        LEntry(
            name: "getChild",
            descr:
                "Gets the first child of the [SObject](lua://SObject), that matches the filter and/or type.",
            args: const {
              LArg<LuaFuncRef>(
                  name: "filter",
                  descr: "The filter to apply to the children.",
                  docTypeOverride: "fun(child: SObject): boolean",
                  kind: ArgKind.optionalNamed),
              LArg<SInterface>(
                name: "type",
                descr: "The type of the children to get.",
                kind: ArgKind.optionalNamed,
              ),
            },
            returnType: SObject,
            returnGeneric: true,
            isAsync: true, ({LuaFuncRef? filter, SInterface? type}) async {
          final children = object!
              .getChildren()
              .nonNulls
              .where((element) => type?.isType(element) ?? true)
              .toList();
          for (final child in children) {
            final res = await filter?.call<bool>([child]) ?? true;
            if (res) return child;
          }
        }),
        LEntry(
            name: "getChildren",
            descr:
                """Returns a list of children of the [SObject](lua://SObject), with the specific type and/or filter.""",
            args: const {
              LArg<LuaFuncRef>(
                  name: "filter",
                  descr: "The filter to apply to the children.",
                  docTypeOverride: "fun(child: SObject): boolean",
                  kind: ArgKind.optionalNamed),
              LArg<SInterface>(
                name: "type",
                descr: "The type of the children to get.",
                kind: ArgKind.optionalNamed,
              )
            },
            returnType: List,
            isAsync: true, ({LuaFuncRef? filter, SInterface? type}) async {
          final children = object!
              .getChildren()
              .nonNulls
              .where((element) => type?.isType(element) ?? true)
              .toList();
          for (final child in object!.getChildren().nonNulls) {
            final res = await filter?.call<bool>([child]) ?? true;
            if (!res) children.remove(child);
          }
          return children;
        }),
        LEntry(
          name: "getParent",
          descr:
              """Returns the parent of the [SObject](lua://SObject), if it has one.

If the object is not a child of another object, this will return null.

The only times where this should return null is when the object is:
1. A [SRoot](lua://SRoot).
2. A [SHeader](lua://SHeader).
3. Removed from the tree.""",
          returnType: SObject,
          returnGeneric: true,
          returnNullable: true,
          () => object!.getParent(),
        ),
        LEntry(
          name: "getDescendants",
          descr:
              """Returns a list of descendants of the [SObject](lua://SObject), with the specific type.

Descendants are not the same as children, as this will include all children and their children, and so on.

If you only want the immediate children of this object, use [getChildren](lua://SObject.getChildren).""",
          returnType: List,
          () => object!.getDescendants().nonNulls.toList(),
        ),
        LEntry(
          name: "getAncestors",
          descr:
              """Returns the ancestors of the [SObject](lua://SObject), if it has one.
              
Ancestors are the chain of SObjects that this object is a child of, and so on.

If you only want the immediate parent of this object, use [getParent](lua://SObject.getParent).""",
          returnType: List,
          () => object!.getAncestors().nonNulls.toList(),
        ),
        LEntry(
          name: "getSiblingAbove",
          descr:
              """Returns the sibling of the [SObject](lua://SObject) above it, if it has one.

If the [SObject](lua://SObject) is the first child, it will return null.

To get the sibling below this one, use [getSiblingBelow](lua://SObject.getSiblingBelow).""",
          returnType: SObject,
          returnNullable: true,
          () => object!.getSiblingAbove(),
        ),
        LEntry(
          name: "getSiblingBelow",
          descr:
              """Returns the sibling of the [SObject](lua://SObject) below it, if it has one.

If the [SObject](lua://SObject) is the first child, it will return null.

To get the sibling above this one, use [getSiblingAbove](lua://SObject.getSiblingAbove).""",
          returnType: SObject,
          returnNullable: true,
          () => object!.getSiblingBelow(),
        ),
        LEntry(
          name: "toJson",
          descr:
              "Returns a json representation of the [SObject](lua://SObject) and its descendants.",
          returnType: Map,
          () => object!.toJson(),
        )
      };
}

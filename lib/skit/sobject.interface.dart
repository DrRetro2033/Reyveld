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
          descr: "Adds a child SObject to the xml node.",
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
          descr: "Removes a child SObject from the xml node.",
          args: const {
            LArg<SObject>(
              name: "child",
              descr: "The child SObject to remove.",
            )
          },
          (SObject child) => object!.removeChild(child),
        ),
        LEntry(
          name: "getChildByTag",
          descr:
              "Returns a child of the SObject by tag. If multiple children have the same tag, only the first one will be returned.",
          args: const {
            LArg<String>(
              name: "tag",
              descr: "The tag of the child to get.",
            ),
          },
          returnType: SObject,
          returnGeneric: true,
          (String tag) => object!.getChild<SObject>(
            filter: (p0) => p0.tag == tag,
          ),
        ),
        LEntry(
            name: "getChild",
            descr:
                "Returns a child of the SObject by a filter. Returns the first child that matches the filter.",
            args: const {
              LArg<LuaFuncRef>(
                name: "filter",
                descr: "The filter to apply to the children.",
                docTypeOverride: "fun(child: SObject): boolean",
              )
            },
            returnType: SObject,
            returnGeneric: true,
            isAsync: true, ({required LuaFuncRef filter}) async {
          for (final child in object!.getChildren().nonNulls) {
            final res = await filter.call<bool>([child]);
            if (res!) return child;
          }
        }),
        LEntry(
            name: "getChildren",
            descr: "Returns a list of all the children of the SObject.",
            args: const {
              LArg<LuaFuncRef>(
                  name: "filter",
                  descr: "The filter to apply to the children.",
                  docTypeOverride: "fun(child: SObject): boolean",
                  kind: ArgKind.optionalPositional),
            },
            returnType: List,
            isAsync: true, ({LuaFuncRef? filter}) async {
          final children = object!.getChildren().nonNulls.toList();
          for (final child in object!.getChildren().nonNulls) {
            if (filter != null) {
              final res = await filter.call<bool>([child]);
              if (!res!) children.remove(child);
            }
          }
          return children;
        }),
        LEntry(
          name: "getParent",
          descr: "Returns the parent of the SObject.",
          returnType: SObject,
          returnGeneric: true,
          () => object!.getParent(),
        ),
        LEntry(
          name: "getDescendants",
          descr: "Returns a list of all the descendants of the SObject.",
          returnType: List,
          () => object!.getDescendants().nonNulls.toList(),
        ),
        LEntry(
          name: "getAncestors",
          descr: "Returns a list of all the ancestors of the SObject.",
          returnType: List,
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

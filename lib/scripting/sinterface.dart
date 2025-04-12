import 'package:arceus/skit/sobject.dart';

/// This acts as an interface between Lua and SKits.
abstract class SInterface<T> {
  String get className;
  String get description;
  Map<String, dynamic> toMap() => {...exports};

  Map<String, dynamic> toLua(Lua state, String luaHash) {
    return {
      "class": className,
      "objHash": luaHash,
      "toString": (Lua state) {
        return toString();
      },
      ...toMap(),
    };
  }

  T? object;
  Map<String, dynamic Function(Lua)> get exports => {};
  Map<String, dynamic Function(Lua)> get statics => {};

  String get interface_ => """
# $className:${description.isEmpty ? "" : "\n$description"}
## Instance methods:${toMap().map((key, value) => MapEntry(key, value.runtimeType)).entries.map((e) => '\n### ${e.key}: Returns ${_formatReturns(e.value.toString())}').join('')}

${statics.isNotEmpty ? "## Static methods:" : ""}${statics.entries.map((e) => '\n### ${e.key}: Returns ${_formatReturns(e.value.runtimeType.toString())}').join('')}
""";

  String _formatReturns(String returns) {
    String currentStr = returns.split("=>").last.trim();
    currentStr = currentStr.replaceAll("<", "(");
    currentStr = currentStr.replaceAll(">", ")");
    return currentStr;
  }

  @override
  String toString() => object.toString();

  bool isType(Object object) {
    return object is T;
  }
}

/// The interface for [SObject]
abstract class SObjectInterface<T extends SObject> extends SInterface<T> {
  @override
  Map<String, dynamic> toMap() => {
        "addChild": (Lua state) async {
          final child = await state.getFromTop<SObject>();
          object!.addChild(child);
        },
        "removeChild": (Lua state) async {
          final child = await state.getFromTop<SObject>();
          object!.removeChild(child);
        },
        "getChild": (Lua state) async {
          final table = await state.getFromTop<Map<String, dynamic>>();
          final type = table.containsKey("class") ? table["class"] : null;
          final attributes = table.containsKey("attrb")
              ? table["attrb"] as Map<String, dynamic>
              : <String, dynamic>{};
          return object!.getChild<SObject>(
            filter: (e) {
              if (type != null) {
                if (Lua.getInterface(e)?.className != type) {
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
        },
        "getChildren": (_) async {
          return object!.getChildren<SObject>();
        },
        "getParent": (_) async {
          return object!.getParent<SObject>();
        },
        "getDescendants": (_) async {
          return object!.getDescendants<SObject>();
        },
        "getAncestors": (_) async {
          return object!.getAncestors<SObject>();
        },
        "getSiblingAbove": (_) async {
          return object!.getSiblingAbove<SObject>();
        },
        "getSiblingBelow": (_) async {
          return object!.getSiblingBelow<SObject>();
        },
        ...exports
      };
}

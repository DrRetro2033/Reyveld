import 'package:reyveld/extensions.dart';
import 'package:reyveld/security/authveld.dart';
import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:reyveld/skit/sobjects/sobjects.dart';

part 'files.creator.dart';
part 'files.g.dart';
part 'files.interface.dart';

@SGen("polfiles")
@LuaClass("""The policy for files.""")
class SPolicyFiles extends SPolicy {
  SPolicyFiles(super._node);

  @override
  childAllowed(object) {
    if (object is Whitelist) {
      return (true, "");
    }
    return (false, "Cannot add a ${object.runtimeType} to an $runtimeType!");
  }

  bool get _externalRead => get("rexter") == "1";
  bool get _externalWrite => get("wexter") == "1";
  bool get _externalCreate => get("cexter") == "1";
  bool get _externalDelete => get("delete") == "1";

  bool get _internalRead => get("rinter") == "1";
  bool get _internalWrite => get("winter") == "1";
  bool get _internalCreate => get("cinter") == "1";
  bool get _internalDelete => get("dinter") == "1";

  Whitelist? get whitelist => getChildSync<Whitelist>();

  @LuaExport("Returns whether or not the file is allowed to be read.")
  bool readAllowed(String filepath, bool isExternal) {
    if (filepath.getExtensions() == "skit") {
      throw AuthVeldException("Cannot read a skit file using this policy!");
    }
    return (isExternal ? _externalRead : _internalRead) &&
        whitelist!.included(filepath);
  }

  @LuaExport("Returns whether or not the file is allowed to be written.")
  bool writeAllowed(String filepath, bool isExternal) {
    if (filepath.getExtensions() == "skit") {
      throw AuthVeldException("Cannot write to a skit file using this policy!");
    }
    return (isExternal ? _externalWrite : _internalWrite) &&
        whitelist!.included(filepath);
  }

  @LuaExport("Returns whether or not the file is allowed to be created.")
  bool createAllowed(String filepath, bool isExternal) {
    if (filepath.getExtensions() == "skit") {
      throw AuthVeldException("Cannot create a skit file using this policy!");
    }
    return (isExternal ? _externalCreate : _internalCreate) &&
        whitelist!.included(filepath);
  }

  @LuaExport("Returns whether or not the file is allowed to be deleted.")
  bool deleteAllowed(String filepath, bool isExternal) {
    if (filepath.getExtensions() == "skit") {
      throw AuthVeldException("Cannot delete a skit file using this policy!");
    }
    return (isExternal ? _externalDelete : _internalDelete) &&
        whitelist!.included(filepath);
  }

  @override
  get safetyLevel {
    if (_externalWrite || _externalDelete) {
      return SPolicySafetyLevel.unsafe;
    } else if (_externalWrite) {
      return SPolicySafetyLevel.warn;
    } else {
      return SPolicySafetyLevel.safe;
    }
  }

  @override
  get description {
    final x = [
      (_externalRead || _internalRead, "read"),
      (_externalWrite || _internalWrite, "write"),
      (_externalCreate || _internalCreate, "create"),
      (_externalDelete || _internalDelete, "delete")
    ];
    return "Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} external and/or internal files.";
  }

  @override
  String details() {
    final x = [
      (_externalRead || _internalRead, "read"),
      (_externalWrite || _internalWrite, "write"),
      (_externalCreate || _internalCreate, "create"),
      (_externalDelete || _internalDelete, "delete")
    ];
    return """
## Allow the application to ${x.where((e) => e.$1).map((e) => e.$2).join(", ")} the following external and/or internal files:
${whitelist!.globs.map((e) => "- ${e.pattern}").join("\n")}
""";
  }
}

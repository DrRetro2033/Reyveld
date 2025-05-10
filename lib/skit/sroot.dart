part of 'sobject.dart';

/// A base class for all root objects.
/// Root objects are objects that are at the root of the skit file, except for the header.
///
/// To reference a root object in the header, use the [SIndent] object.
abstract class SRoot extends SObject {
  SRoot(super.node);

  bool delete = false;

  String get hash => get("hash") ?? "";
  set hash(String value) => set("hash", value);

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SRoot) return false;
    if (other.runtimeType != runtimeType) return false;
    if (other.hash != hash) return false;
    return true;
  }

  @override
  int get hashCode => hash.hashCode;

  void markForDeletion() {
    kit!.unloadRoot(this);
    delete = true;
  }
}

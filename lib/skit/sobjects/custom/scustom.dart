import 'package:reyveld/skit/sobject.dart';

part 'scustom.creator.dart';
part 'scustom.g.dart';
part 'scustom.interface.dart';

/// Stores any custom data that is not covered by the other [SObject]s.
@SGen("custom")
class SCustom extends SObject {
  /// This is the custom type assigned by the creator of this [SCustom].
  String get type => get("type")!;

  SCustom(super._node);

  /// Gets an attribute of the xml node as an int.
  int? getInt(String key) {
    if (!has(key)) {
      return null;
    }
    return int.tryParse(get(key)!);
  }

  /// Sets an attribute of the xml node as an int.
  void setInt(String key, int value) {
    set(key, value.toString());
  }

  /// Gets an attribute of the xml node as a string.
  String? getString(String key) {
    if (!has(key)) {
      return null;
    }
    return get(key);
  }

  /// Sets an attribute of the xml node as a string.
  void setString(String key, String value) {
    set(key, value);
  }

  /// Gets an attribute of the xml node as a bool.
  bool? getBool(String key) {
    if (!has(key)) {
      return null;
    }
    return get(key) == "1";
  }

  /// Sets an attribute of the xml node as a bool.
  void setBool(String key, bool value) {
    set(key, value ? "1" : "0");
  }
}

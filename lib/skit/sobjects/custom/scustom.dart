import 'package:reyveld/skit/sobject.dart';

part 'scustom.creator.dart';
part 'scustom.g.dart';
part 'scustom.interface.dart';

@SGen("custom")
class SCustom extends SObject {
  String get type => get("type")!;

  SCustom(super._node);

  int? getInt(String key) {
    if (!has(key)) {
      return null;
    }
    return int.tryParse(get(key)!);
  }

  void setInt(String key, int value) {
    set(key, value.toString());
  }

  String? getString(String key) {
    if (!has(key)) {
      return null;
    }
    return get(key);
  }

  void setString(String key, String value) {
    set(key, value);
  }
}

import 'package:arceus/skit/sobject.dart';

part 'scustom.creator.dart';
part 'scustom.g.dart';
part 'scustom.interface.dart';

@SGen("custom")
class SCustom extends SObject {
  String get type => get("type", decode: true)!;

  SCustom(super._node);

  int? getInt(String key) {
    if (!has(key)) {
      return null;
    }
    return int.tryParse(get(key, decode: true)!);
  }

  void setInt(String key, int value) {
    set(key, value.toString());
  }

  String? getString(String key) {
    if (!has(key)) {
      return null;
    }
    return get(key, decode: true);
  }

  void setString(String key, String value) {
    set(key, encodeText(value));
  }
}

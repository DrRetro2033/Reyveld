import 'package:uuid/uuid.dart';

final uuid = Uuid();

/// # `String` generateUUID()
/// ## Generates a random UUID for unique hashes.
String generateUUID() {
  String hash = uuid.v4();
  hash = hash.replaceAll("-", "");
  return hash;
}

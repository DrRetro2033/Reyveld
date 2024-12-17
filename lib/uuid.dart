import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// # `String` generateUUID()
/// ## Generates a random UUID for unique hashes.
String generateUUID() {
  String hash = _uuid.v4();
  hash = hash.replaceAll("-", "");
  return hash;
}

String generateUniqueHash(Set<String> existingHashes, {int length = 32}) {
  String hash = generateUUID();
  int retries = 8192;
  while (existingHashes.contains(hash.substring(0, length))) {
    if (retries <= 0) {
      throw Exception("Unable to generate a unique hash! Retries exceeded.");
    }
    hash = generateUUID();
    retries--;
  }
  return hash.substring(0, length);
}

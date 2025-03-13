import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// # `String` generateUUID()
/// ## Generates a random UUID for unique hashes.
String generateUUID() {
  String hash = _uuid.v4();
  // hash = hash.replaceAll("-", "");
  return hash;
}

String generateUniqueHash(Set<String> existingHashes) {
  String hash = generateUUID();
  int retries = 8192;
  while (existingHashes.contains(hash)) {
    if (retries <= 0) {
      throw Exception("Unable to generate a unique hash! Retries exceeded.");
    }
    hash = generateUUID();
    retries--;
  }
  return hash;
}

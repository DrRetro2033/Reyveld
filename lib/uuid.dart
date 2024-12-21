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
  if (existingHashes.length >= (1 << (length * 4))) {
    throw Exception("Unable to generate a unique hash! No available hashes.");
  }

  String hash = generateUUID();
  while (existingHashes.contains(hash.substring(0, length))) {
    hash = generateUUID();
  }
  return hash.substring(0, length);
}

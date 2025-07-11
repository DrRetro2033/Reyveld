import 'package:uuid/uuid.dart';

final _uuid = Uuid();
String generateUniqueHash(Set<String> existingHashes) {
  String hash = _uuid.v4();
  int retries = 8192;
  while (existingHashes.contains(hash)) {
    if (retries <= 0) {
      throw Exception("Unable to generate a unique hash! Retries exceeded.");
    }
    hash = generateUUIDv4();
    retries--;
  }
  return hash;
}

String generateUUIDv4() {
  return _uuid.v4();
}

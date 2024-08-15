import 'package:uuid/uuid.dart';

final uuid = Uuid();

String generateUUID() {
  String hash = uuid.v4();
  hash = hash.replaceAll("-", "");
  return hash;
}

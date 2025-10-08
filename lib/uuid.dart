import 'package:ulid/ulid.dart';

String generateUUID() {
  return Ulid().toUuid();
}

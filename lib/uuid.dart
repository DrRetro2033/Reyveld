import 'package:uuid/uuid.dart';

final _uuid = Uuid();

String generateUUIDv4() {
  return _uuid.v4();
}

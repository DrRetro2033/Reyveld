import 'dart:async';

import 'package:arceus/main.dart' as server;

/// Entry point for the Arceus server when calling "dart run arceus".
Future<void> main(List<String> args) async {
  await server.main(args);
}

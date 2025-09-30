import 'dart:async';

import 'package:reyveld/main.dart' as server;

/// Entry point for the Reyveld server when calling "dart run reyveld".
Future<void> main(List<String> args) async {
  await server.main(args);
}

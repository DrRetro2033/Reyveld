import 'package:args/command_runner.dart';
import '/server.dart' as server;

class StartCommand extends Command {
  @override
  final name = "start";
  @override
  final description = "Start Reyveld as a WebSocket server.";
  @override
  Future<void> run() async => await server.runServer();
}

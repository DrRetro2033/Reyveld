import 'dart:io';

import 'package:arceus/uuid.dart';

/// Represents a ticket that is being worked on.
/// A way to send the progress of a task to the client.
/// [Ticket]s can be started and finished.
/// [Ticket]s are unique to each [WebSocket] connection.
/// [WebSocket]s can have multiple [Ticket]s for different tasks.
class Ticket {
  static final Map<WebSocket, Set<Ticket>> tickets = {};
  final WebSocket socket;
  final String id;
  final String name;
  DateTime? started;
  DateTime? finished;
  Ticket(this.socket, {this.name = "Generic Ticket"})
      : id = generateUniqueHash(
            tickets[socket]?.map((e) => e.id).toSet() ?? {}) {
    tickets[socket] ??= {};
  }

  Future<void> start() async {
    started = DateTime.now();
    tickets[socket]!.add(this);
    socket.add("$id:$name:EVENT:START");
  }

  Future<void> message(dynamic data) async =>
      socket.add("$id:$name:MESSAGE:$data");

  Future<void> finish([dynamic result]) async {
    finished = DateTime.now();
    if (result != null) socket.add("$id:$name:RESULT:$result");
    socket.add("$id:$name:EVENT:FINISH");
    tickets[socket]!.remove(this);
  }
}

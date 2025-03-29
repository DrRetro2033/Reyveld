import 'dart:io';

import 'package:arceus/ticket.dart';
export 'package:arceus/ticket.dart';

abstract class Command {
  String get name;
  String get ticketName;

  Future<dynamic> execute(Ticket ticket, List<String> args);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is Command && other.name == name;
}

class Runner {
  Set<Command> commands = {};

  void add(Command command) => commands.add(command);

  Future<void> run(WebSocket socket, String command) async {
    final x =
        commands.where((element) => element.name == command.split(" ").first);
    if (x.isEmpty) throw Exception("Command not found.");
    final commandInstance = x.first;
    final ticket = Ticket(socket, name: commandInstance.ticketName);
    await ticket.start();
    await commandInstance.execute(ticket, [...command.split(" ").skip(1)]).then(
        (value) => ticket.finish(value));
  }
}

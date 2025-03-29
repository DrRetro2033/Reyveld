import 'package:arceus/command.dart';

class TestCommand extends Command {
  @override
  String get name => "test";

  @override
  String get ticketName => "Test";

  @override
  Future<void> execute(Ticket ticket, List<String> args) async {
    await ticket.message("Hello World!");
    await ticket.message("This is a test.");
  }
}

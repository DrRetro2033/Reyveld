import 'package:args/command_runner.dart';

class PacksCommand extends Command {
  PacksCommand() {
    addSubcommand(AddPackCommand());
    addSubcommand(RemovePackCommand());
    addSubcommand(ListPacksCommand());
    addSubcommand(NewCommand());
  }

  @override
  String get name => "packs";

  @override
  String get description => "Manage packs.";
}

class AddPackCommand extends Command {
  AddPackCommand() {
    return;
  }

  @override
  String get name => "add";

  @override
  String get description => "Add a pack.";
}

class RemovePackCommand extends Command {
  RemovePackCommand() {
    return;
  }

  @override
  String get name => "remove";

  @override
  String get description => "Remove a pack.";
}

class ListPacksCommand extends Command {
  ListPacksCommand() {
    return;
  }

  @override
  String get name => "list";

  @override
  String get description => "List packs.";
}

class NewCommand extends Command {
  NewCommand() {
    return;
  }

  @override
  String get name => "new";

  @override
  String get description => "Create a new pack.";
}

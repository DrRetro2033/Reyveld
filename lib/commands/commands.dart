import 'package:args/command_runner.dart';

import 'run.dart';
import 'start.dart';
import 'authveld.dart';
import 'docregen.dart';

CommandRunner get commands => CommandRunner("reyveld", """
A multi-purpose toolbox for working with files, with a focus on simplicity and ease of use.
""")
  ..addCommand(RunCommand())
  ..addCommand(StartCommand())
  ..addCommand(AuthVeldCommand())
  ..addCommand(DocRegenCommand());

part of 'header.dart';

final class SHeaderInterface extends SInterface<SHeader> {
  @override
  get className => "SHeader";

  @override
  get classDescription => """
A header node of a SERE kit file.
This is the top level node of the kit file, and contains information about the kit, like constellation structures, library info, etc.
""";

  @override
  get parent => SObjectInterface();
}

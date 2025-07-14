part of 'author.dart';

class SAuthorInterface extends SInterface<SAuthor> {
  @override
  SInterface? get parent => SObjectInterface();

  @override
  String get className => "SAuthor";

  @override
  // TODO: implement allExports
  get exports => {
        LEntry(
            name: "isTrusted",
            descr: "Returns true if this author is trusted.",
            isAsync: true,
            returnType: bool,
            () async => await object!.isTrusted()),
        LEntry(
            name: "trust",
            descr: "Trust the author.",
            isAsync: true,
            () async => await object!.trust())
      };
}

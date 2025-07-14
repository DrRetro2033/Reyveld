import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:basic_utils/basic_utils.dart';

part 'author.creator.dart';
part 'author.g.dart';
part 'author.interface.dart';

/// Repersents an author of an Arceus library.
@SGen("author")
class SAuthor extends SRoot {
  String get name => get("name", decode: true)!;
  String? get github => get("github", decode: true);
  RSAPublicKey get publicKey {
    return CryptoUtils.rsaPublicKeyFromPem(
      decodeText(innerText!),
    );
  }

  @override
  Future<SRAuthor> newIndent() async => await SRAuthorCreator(hash).create();

  SAuthor(super.node);

  Future<bool> isTrusted() async => Arceus.isTrustedAuthor(this);
  Future<void> trust() async => Arceus.trustAuthor(this);
}

@SGen("rauthor")
class SRAuthor extends SIndent<SAuthor> {
  SRAuthor(super.node);
}

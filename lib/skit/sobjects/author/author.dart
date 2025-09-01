import 'package:reyveld/reyveld.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:basic_utils/basic_utils.dart';

part 'author.creator.dart';
part 'author.g.dart';
part 'author.interface.dart';

/// Repersents an author of an Reyveld library.
@SGen("author")
class SAuthor extends SRoot {
  String get name => get("name")!;
  String? get github => get("github");
  RSAPublicKey get publicKey {
    return CryptoUtils.rsaPublicKeyFromPem(
      decodeText(innerText!),
    );
  }

  @override
  Future<SRAuthor> newIndent() async => await SRAuthorCreator(hash).create();

  SAuthor(super._node);

  Future<bool> isTrusted() async => Reyveld.isTrustedAuthor(this);
  Future<void> trust() async => Reyveld.trustAuthor(this);
}

@SGen("rauthor")
class SRAuthor extends SIndent<SAuthor> {
  SRAuthor(super._node);
}

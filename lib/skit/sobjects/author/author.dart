import 'package:reyveld/reyveld.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:basic_utils/basic_utils.dart';

part 'author.creator.dart';
part 'author.g.dart';
part 'author.interface.dart';

/// Repersents an author of an Reyveld library.
@SGen("author")
class SAuthor extends SRoot {
  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;

  /// The name of the author.
  String get name => get("name")!;

  /// The github email of the author.
  String? get github => get("github");

  /// The public key of the author.
  RSAPublicKey get publicKey {
    if (cdata == null) {
      final pub = innerText!;
      clearInnerText();
      cdata = decodeText(pub).codeUnits;
    }
    return CryptoUtils.rsaPublicKeyFromPem(
      String.fromCharCodes(cdata!),
    );
  }

  @override
  Future<SRAuthor> newIndent() async => await SRAuthorCreator(hash).create();

  SAuthor(super._node);

  /// Returns whether the author is trusted by the user.
  Future<bool> isTrusted() async => Reyveld.isTrustedAuthor(this);

  /// Trusts the author.
  Future<void> trust() async => Reyveld.trustAuthor(this);

  /// Returns whether the author is the user.
  Future<bool> isMe() async => await Reyveld.publicKey == publicKey;

  @override
  int get hashCode => publicKey.hashCode;

  @override
  bool operator ==(Object other) =>
      other is SAuthor && other.publicKey == publicKey;
}

@SGen("rauthor")
class SRAuthor extends SIndent<SAuthor> {
  SRAuthor(super._node);
}

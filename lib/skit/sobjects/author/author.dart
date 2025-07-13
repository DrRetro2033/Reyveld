import 'package:arceus/skit/sobject.dart';
import 'package:basic_utils/basic_utils.dart';

part 'author.creator.dart';
part 'author.g.dart';

/// Repersents an author of an Arceus library.
@SGen("author")
class SAuthor extends SRoot {
  String get name => decodeText(get("name")!);
  RSAPublicKey get publicKey {
    return CryptoUtils.rsaPublicKeyFromPem(
      decodeText(innerText!),
    );
  }

  SAuthor(super.node);
}

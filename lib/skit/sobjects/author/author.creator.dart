part of 'author.dart';

class SAuthorCreator extends SCreator<SAuthor> {
  /// The name of the author.
  final String name;

  /// The public key of the author.
  final RSAPublicKey publicKey;
  SAuthorCreator({required this.name, required this.publicKey});

  @override
  build(builder) {
    builder.attribute("name", name);
    builder.cdata(CryptoUtils.encodeRSAPublicKeyToPem(publicKey));
  }
}

typedef SRAuthorCreator = SIndentCreator<SRAuthor>;

part of 'author.dart';

class SAuthorCreator extends SCreator<SAuthor> {
  final String name;
  final RSAPublicKey publicKey;
  SAuthorCreator({required this.name, required this.publicKey});

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder.text(CryptoUtils.encodeRSAPublicKeyToPem(publicKey)
            .replaceAll("\n", String.fromCharCode(0)));
      };
}

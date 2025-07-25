part of 'author.dart';

class SAuthorCreator extends SCreator<SAuthor> {
  final String name;
  final RSAPublicKey publicKey;
  SAuthorCreator({required this.name, required this.publicKey});

  @override
  get creator => (builder) {
        builder.attribute("name", name);
        builder
            .text(encodeText(CryptoUtils.encodeRSAPublicKeyToPem(publicKey)));
      };
}

typedef SRAuthorCreator = SIndentCreator<SRAuthor>;

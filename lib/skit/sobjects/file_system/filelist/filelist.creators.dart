part of 'filelist.dart';

class WhitelistCreator extends SCreator<Whitelist> {
  final List<String> list;

  WhitelistCreator(this.list);

  @override
  get creator => (builder) {
        builder.text(base64Encode(utf8.encode(list.join("\n"))));
      };
}

class BlacklistCreator extends SCreator<Blacklist> {
  final List<String> list;

  BlacklistCreator(this.list);

  @override
  get creator => (builder) {
        builder.text(base64Encode(utf8.encode(list.join("\n"))));
      };
}

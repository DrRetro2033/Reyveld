import 'dart:convert';
import 'dart:io';

extension Compression on String {
  String compress() {
    return gzip.encode(utf8.encode(this)).toString();
  }

  String decompress() {
    return utf8.decode(gzip.decode(gzip.encode(utf8.encode(this))));
  }

  String fixPath() {
    String path = replaceAll("\"", "");
    return path.replaceAll("\\", "/");
  }
}

extension Compression on String {
  String fixPath() {
    String path = replaceAll("\"", "");
    return path.replaceAll("\\", "/");
  }
}

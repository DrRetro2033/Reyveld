extension Compression on String {
  String fixPath() {
    String path = replaceAll("\"", "");
    return path.replaceAll("\\", "/");
  }

  String makeRelPath(String relativeTo) {
    return replaceFirst("$relativeTo\\", "").fixPath();
  }

  String getFilename() {
    String path = fixPath();
    return path.split("/").last;
  }
}

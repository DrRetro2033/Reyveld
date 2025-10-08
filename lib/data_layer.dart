abstract class DataLayer {
  String get name;
  String get version;
  String get description;

  const DataLayer();

  /// Encodes a stream of bytes.
  Stream<List<int>> encodeStream(Stream<List<int>> input);

  /// Decodes a stream of bytes.
  Stream<List<int>> decodeStream(Stream<List<int>> input);

  Future<List<int>> encode(List<int> input) => encodeStream(Stream.value(input))
      .toList()
      .then((chunks) => chunks.expand((c) => c).toList());

  Future<List<int>> decode(List<int> input) => decodeStream(Stream.value(input))
      .toList()
      .then((chunks) => chunks.expand((c) => c).toList());
}

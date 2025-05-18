part of 'sobject.dart';

/// A base factory for parsing [SObject]s from xml.
/// Subclasses should be created as follows:
/// ```dart
/// class MySFactory extends SFactory<MySObject> {
///   ...
/// }
/// ```
abstract class SFactory<T extends SObject> {
  /// The tag of the associated xml node.
  /// Will be checked if unique in [_sobjectFactories] in serekit.factories.dart.
  String get tag;

  /// Loads the [SObject] from the xml node.
  /// The [SKit] and the [XmlElement] are passed for accessing the underlying xml data,
  /// and the file it came from.
  T load(XmlElement node);

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SFactory) return false;
    if (other.tag != tag) return false;
    return true;
  }

  @override
  int get hashCode => tag.hashCode;
}

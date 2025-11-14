part of 'sobject.dart';

/// A base creator for creating [SObject]s.
/// Creation was at first delegated to [SFactory], however
/// it was moved to its own base class for more stricter
/// control over the creation process.
///
/// All subclasses should implement the [creator] method.
/// To create a [SObject], you should call the [create] method.
///
/// Example:
/// ```dart
/// class MySCreator extends SCreator<MySObject> {
///
///   /// This is an example of required parameters that must be given to the [SCreator].
///   final String name;
///
///   /// This is an example of optional parameters that can be given to the [SCreator].
///   final DateTime? date;
///
///   MySCreator(this.name, {this.date = null});
///
///   @override
///   build(builder) {
///     /// No need to add element here, it will be added by the creator function
///     /// as it is a nested builder.
///     builder.attribute("name", name);
///     builder.attribute("date", (date ?? DateTime.now()).toIso8601String());
///   }
/// }
///
/// Future<SObject> createObj(SKit kit) async {
///   return await MySCreator("Hello").create(kit);
/// }
/// ```
abstract class SCreator<T extends SObject> {
  SCreator();

  T create() {
    final builder = ModifiedXmlBuilder();

    /// Create the outer element with the correct tag,
    /// and then call the [creator] function
    builder.element(getSFactory<T>().tag, nest: () => build(builder));

    final frag = builder
        .buildDocument(); // Builds the document that contains our element.

    /// Load the [SObject].
    final obj = getSFactory<T>().load(frag.rootElement);

    return obj;
  }

  /// [build] must never be asynchronous, as the xml package does not play nicely with it.
  ///
  /// If you need to do asynchronous work, create a static function in the [SCreator] instead.
  void build(ModifiedXmlBuilder builder);
}

/// This is a modified version of the [XmlBuilder] that will automatically encode text using [encodeText].
///
/// This is done so that there are no conflicts with the xml parser.
class ModifiedXmlBuilder extends XmlBuilder {
  @override
  void attribute(String name, Object? value,
          {String? namespace, XmlAttributeType? attributeType}) =>
      super.attribute(name, encodeText(value.toString()),
          namespace: namespace, attributeType: attributeType);

  /// Creates a boolean attribute (true = 1, false = 0).
  void boolAttri(String name, bool value,
          {String? namespace, XmlAttributeType? attributeType}) =>
      attribute(name, value ? "1" : "0",
          namespace: namespace, attributeType: attributeType);

  /// Use this to add a [SObject] to the xml document.
  /// The [SObject] will be converted to xml and added to the node.
  void sobject(SObject obj) => xml(obj.toXmlString());
}

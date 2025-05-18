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
///   get creator => (builder) {
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

  FutureOr<T> create() async {
    final builder = XmlBuilder();

    /// Does something before creation asyncronously
    await beforeCreate();

    /// Create the outer element with the correct tag,
    /// and then call the [creator] function
    builder.element(getSFactory<T>().tag, nest: () {
      creator(builder);
    });

    final frag = builder
        .buildDocument(); // Builds the document that contains our element.

    /// Load the [SObject].
    final obj = getSFactory<T>().load(frag.rootElement);

    /// Does something after creation asynchronously.
    await afterCreate(obj);

    return obj;
  }

  FutureOr<void> Function() get beforeCreate => () async {
        return;
      };

  FutureOr<void> Function(T) get afterCreate => (T obj) async {
        return;
      };

  /// Creator must never be asynchronous, as the xml package does not play nicely with it.
  /// It must be synchronous. However, if you need to use asyncronous code,
  /// use [beforeCreate] to do stuff before creating the [SObject].
  void Function(XmlBuilder builder) get creator;
}

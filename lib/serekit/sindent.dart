part of 'sobject.dart';

/// This [SObject] is used to indicate a [SRoot] reference inside the header of the skit file.
/// The [hash] is the hash of the [SRoot] that is being referenced.
/// The [hash] is unique to the type of [SRoot] that is being referenced.
abstract class SIndent<T extends SRoot> extends SObject {
  bool _delete = false;
  bool get isDeleted => _delete;

  String get hash => get("hash")!;
  SIndent(super.kit, super.node);

  Future<T?> getRef() async {
    return await kit.getRoot(filterRoots: (e) => e.hash == hash);
  }

  /// Returns true if the [SIndent] is for the specified [SRoot].
  bool isFor(SRoot root) {
    if (root is T) {
      return root.hash == hash;
    }
    return false;
  }

  /// Marks the [SIndent] for deletion.
  /// The [SIndent] and its refered [SRoot] will be deleted when the kit file is saved.
  void markForDeletion() {
    unparent();
    _delete = true;
    kit.addIndent(this);
  }

  @override
  operator ==(Object other) => other is SIndent<T> && other.hash == hash;

  @override
  int get hashCode => hash.hashCode;
}

/// A base creator for creating [SIndent]s.
/// This is not abstract, so it can be used in a typedef instead of a subclass.
///
/// Example of using a subclass:
/// ```dart
/// class MySIndentCreator extends SIndentCreator<MySIndent> {
///   ...
/// }
/// ```
/// Example of using a typedef:
/// ```dart
/// typedef MySIndentCreator = SIndentCreator<MySIndent>;
/// ```
class SIndentCreator<T extends SIndent> extends SCreator {
  final String hash;
  SIndentCreator(this.hash);

  @override
  FutureOr<T> create(SKit kit) async {
    final builder = XmlBuilder();

    /// Does something before creation asyncronously
    await beforeCreate(kit);

    builder.element(getSFactory<T>().tag, nest: () {
      builder.attribute("hash", hash);
      creator(builder);
    });

    final frag = builder.buildDocument(); // build the document

    /// load the [SObject]
    return getSFactory<T>().load(kit, frag.rootElement);
  }

  @override
  get creator => (builder) {};
}

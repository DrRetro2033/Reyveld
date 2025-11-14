part of 'sobject.dart';

/// This [SObject] is used to indicate a [SRoot] reference inside the header of the skit file.
/// The [id] is the hash of the [SRoot] that is being referenced.
/// The [id] is unique to the type of [SRoot] that is being referenced.
abstract class SIndent<T extends SRoot> extends SObject {
  @override
  childAllowed(object) => SObject.zeroChildrenAllowed;

  @override
  onSave(kit) async {
    if (kit.isMarkedForDeletion(id)) {
      unparent();
    }
  }

  bool _delete = false;

  /// Returns true if the [SIndent] is marked for deletion.
  /// Cannot be set directly, use [markForDeletion] instead.
  bool get isDeleted => _delete;

  /// The hash of the [SRoot] that is being referenced.
  String get id => get("hash")!;
  SIndent(super._node);

  /// Returns the [SRoot] that is being referenced by the [SIndent].
  Future<T?> getRef() async {
    return await kit.getRoot<T>(filterRoots: (e) => e.id == id);
  }

  /// Returns true if the [SIndent] is for the specified [SRoot].
  bool isFor(SRoot root) {
    if (root is T) {
      return root.id == id;
    }
    return false;
  }

  /// Marks the refered [SRoot] for deletion, and unparents the [SIndent].
  /// If you only want to delete the [SIndent], use [unparent] instead.
  void markForDeletion() {
    unparent();
    _delete = true;
    kit.addIndent(this);
  }

  @override
  operator ==(Object other) => other is SIndent<T> && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
  final String id;
  SIndentCreator(this.id);

  @override
  T create() {
    final builder = ModifiedXmlBuilder();

    builder.element(getSFactory<T>().tag, nest: () {
      builder.attribute("hash", id);
      build(builder);
    });

    final frag = builder.buildDocument(); // build the document

    /// load the [SObject]
    return getSFactory<T>().load(frag.rootElement);
  }

  @override
  build(_) {}
}

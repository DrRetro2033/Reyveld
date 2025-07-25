part of 'skit.dart';

// This file contains all of the [SFactory]s for every [SObject] subclass.

/// The set of all [SFactory] objects.
/// This is used to load [SObject]s from xml.
Set<SFactory> get sobjectFactories => {
      ConstellationFactory(),
      StarFactory(),
      SHeaderFactory(),
      SArchiveFactory(),
      SFileFactory(),
      SRArchiveFactory(),
      SRFileFactory(),
      SDescriptionFactory(),
      WhitelistFactory(),
      BlacklistFactory(),
      SAuthorFactory(),
      SRAuthorFactory(),
      SCustomFactory()
    };

/// Get the factory for the given [SObject] subclass.
/// Throws an exception if no factory is found.
SFactory<T> getSFactory<T extends SObject>([String? tag]) {
  final factories = sobjectFactories.whereType<SFactory<T>?>();
  SFactory<T>? factory = factories.firstOrNull;
  if (tag != null) {
    factory = factories.firstWhere((e) => e!.tag == tag, orElse: () => null);
  }
  if (factory == null) {
    throw "No factory found for $T with tag '$tag'!";
  }
  return factory;
}

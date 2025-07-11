part of 'skit.dart';

// This file contains all of the [SFactory]s for every [SObject] subclass.

/// The set of all [SFactory] objects.
/// This is used to load [SObject]s from xml.
final Set<SFactory> sobjectFactories = {
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
    Arceus.talker.critical(
        "No factory found for $T with tag '$tag'! Falling back to generic SFactory. Please make sure you added a factory for this tag in serekit.factories.dart for correct behavior.");
    factory = GenericFactory() as SFactory<T>;
  }
  return factory;
}

/// This is a fallback factory for [SObject]s that don't have a custom factory.
class GenericFactory extends SFactory<SObject> {
  @override
  SObject load(XmlElement node) => SObject(node);

  @override
  String get tag => "";
}

part of 'serekit.dart';

// This file contains all of the [SFactory]s for every [SObject] subclass.

/// The set of all [SFactory] objects.
/// This is used to load [SObject]s from xml.
final Set<SFactory> _sobjectFactories = {
  ConstellationFactory(),
  StarFactory(),
  SHeaderFactory(),
  SArchiveFactory(),
  SRArchiveFactory(),
  SFileFactory(),
  ArceusSettingsFactory(),
  DescriptionFactory(),
  AddonFactory(),
};

/// Get the factory for the given [SObject] subclass.
/// Returns null if not found.
SFactory<T> getSFactory<T extends SObject>([String? tag]) {
  final factories = _sobjectFactories.whereType<SFactory<T>?>();
  SFactory<T>? factory = factories.first;
  if (tag != null) {
    factory = factories.firstWhere((e) => e!.tag == tag, orElse: () => null);
  }
  if (factory == null) {
    throw Exception(
        "No factory found for $T with tag $tag. Please make sure you added the factory for this tag in serekit.g.dart!");
  }
  return factory;
}

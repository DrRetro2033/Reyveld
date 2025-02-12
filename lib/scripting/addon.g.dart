// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addon.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class AddonFactory extends SFactory<Addon> {
  AddonFactory();

  @override
  Addon load(SKit kit, XmlNode node) => Addon(kit, node);

  @override
  String get tag => "addon";

  @override
  get creator => (builder, [attributes = const {}]) {
        builder.element(tag, nest: () {
          Addon.create(builder, attributes);
        });
      };
}

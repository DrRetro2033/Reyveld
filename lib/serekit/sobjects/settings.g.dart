// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class ArceusSettingsFactory extends SFactory<ArceusSettings> {
  ArceusSettingsFactory();

  @override
  ArceusSettings load(SKit kit, XmlNode node) => ArceusSettings(kit, node);

  @override
  String get tag => "settings";

  @override
  get creator => (builder, [attributes = const {}]) {
        builder.element(tag, nest: () {
          ArceusSettings.create(builder, attributes);
        });
      };
}

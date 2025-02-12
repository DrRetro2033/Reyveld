// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constellation.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class ConstellationFactory extends SFactory<Constellation> {
  ConstellationFactory();

  @override
  Constellation load(SKit kit, XmlNode node) => Constellation(kit, node);

  @override
  String get tag => "const";

  @override
  get creator => (builder, [attributes = const {}]) {
        builder.element(tag, nest: () {
          Constellation.create(builder, attributes);
        });
      };
}

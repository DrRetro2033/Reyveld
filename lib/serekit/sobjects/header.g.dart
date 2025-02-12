// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class SHeaderFactory extends SFactory<SHeader> {
  SHeaderFactory();

  @override
  SHeader load(SKit kit, XmlNode node) => SHeader(kit, node);

  @override
  String get tag => "sere";

  @override
  get creator => (builder, [attributes = const {}]) {
        builder.element(tag, nest: () {
          SHeader.create(builder, attributes);
        });
      };
}

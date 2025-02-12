// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'description.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class DescriptionFactory extends SFactory<Description> {
  DescriptionFactory();

  @override
  Description load(SKit kit, XmlNode node) => Description(kit, node);

  @override
  String get tag => "descr";

  @override
  get creator => (builder, [attributes = const {}]) {
        builder.element(tag, nest: () {
          Description.create(builder, attributes);
        });
      };
}

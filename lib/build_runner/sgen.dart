// ignore_for_file: depend_on_referenced_packages

part of 'package:arceus/builder.dart';

class SGenGenerator extends GeneratorForAnnotation<SGen> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@SGen can only be used on classes.',
        element: element,
      );
    }

    if (!element.allSupertypes.any((e) => e.getDisplayString() == "SObject")) {
      throw InvalidGenerationSourceError(
        '@SGen can only be used on classes that extend SObject.',
        element: element,
      );
    }

    final createMethod = element.getMethod("create");
    if (createMethod == null || !createMethod.isStatic) {
      throw InvalidGenerationSourceError(
        '@SGen can only be used on classes that have a static create method.',
        element: element,
      );
    }

    if (!createMethodHasRequiredParms(createMethod.parameters)) {
      throw InvalidGenerationSourceError(
        '@SGen can only be used on classes that have a static create method with XmlBuilder, and Map<String, dynamic> parameters. For example: static create(XmlBuilder builder, Map<String, dynamic> attributes)',
        element: element,
      );
    }

    final className = element.name;
    final factoryClassName = '${className}Factory';
    final tagName = annotation.peek('tag')?.stringValue ?? className;
    return '''
      class $factoryClassName extends SFactory<$className> {

        $factoryClassName();

        @override
        $className load(SKit kit, XmlNode node) => $className(kit, node);

        @override
        String get tag => "$tagName";

        @override
        get creator => (builder, [attributes = const {}]) {
          builder.element(tag, nest: () {
            $className.create(builder, attributes);
          });
        };
      }
    ''';
  }

  bool createMethodHasRequiredParms(List<ParameterElement> parameters) {
    if (parameters.isEmpty || parameters.length != 2) {
      return false;
    }
    if (parameters.any((e) => !e.isRequiredPositional)) {
      return false;
    }
    if (parameters[0].type.getDisplayString() != "XmlBuilder" ||
        !parameters[1].type.isDartCoreMap) {
      return false;
    }
    return true;
  }
}

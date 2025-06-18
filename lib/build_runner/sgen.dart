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
    final className = element.name;
    final factoryClassName = '${className}Factory';
    final tagName = annotation.peek('tag')?.stringValue ?? className;
    return '''
      class $factoryClassName extends SFactory<$className> {

        $factoryClassName();

        @override
        $className load(XmlElement node) => $className(node);

        @override
        String get tag => "$tagName";
      }
    ''';
  }
}

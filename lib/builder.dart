// ignore_for_file: depend_on_referenced_packages

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/ast/ast.dart';

part 'package:reyveld/build_runner/sgen.dart';
part 'package:reyveld/build_runner/sinterface.dart';

Builder sgenBuilder(BuilderOptions options) =>
    SharedPartBuilder([SGenGenerator()], 'sgen');

Builder sinterfaceBuilder(BuilderOptions options) => PartBuilder(
      [SInterfaceGenerator()],
      '.interface.dart',
    );

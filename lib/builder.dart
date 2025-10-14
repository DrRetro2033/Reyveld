// ignore_for_file: depend_on_referenced_packages

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:reyveld/skit/sobject.dart';
import 'package:analyzer/dart/element/element2.dart';
part 'package:reyveld/build_runner/sgen.dart';

Builder sgenBuilder(BuilderOptions options) =>
    SharedPartBuilder([SGenGenerator()], 'sgen');

part of 'library.dart';

class SLibraryFactory extends SFactory<SLibrary> {
  SLibraryFactory();

  @override
  SLibrary load(XmlElement node) => SLibrary(node);

  @override
  String get tag => "archive";
}

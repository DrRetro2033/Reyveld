// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_system.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class SArchiveFactory extends SFactory<SArchive> {
  SArchiveFactory();

  @override
  SArchive load(SKit kit, XmlNode node) => SArchive(kit, node);

  @override
  String get tag => "archive";
}

class SFileFactory extends SFactory<SFile> {
  SFileFactory();

  @override
  SFile load(SKit kit, XmlNode node) => SFile(kit, node);

  @override
  String get tag => "file";
}

class SRArchiveFactory extends SFactory<SRArchive> {
  SRArchiveFactory();

  @override
  SRArchive load(SKit kit, XmlNode node) => SRArchive(kit, node);

  @override
  String get tag => "rarchive";
}

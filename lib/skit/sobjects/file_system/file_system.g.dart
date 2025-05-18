// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_system.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class SArchiveFactory extends SFactory<SArchive> {
  SArchiveFactory();

  @override
  SArchive load(XmlElement node) => SArchive(node);

  @override
  String get tag => "archive";
}

class SFileFactory extends SFactory<SFile> {
  SFileFactory();

  @override
  SFile load(XmlElement node) => SFile(node);

  @override
  String get tag => "file";
}

class SRArchiveFactory extends SFactory<SRArchive> {
  SRArchiveFactory();

  @override
  SRArchive load(XmlElement node) => SRArchive(node);

  @override
  String get tag => "rarchive";
}

class SRFileFactory extends SFactory<SRFile> {
  SRFileFactory();

  @override
  SRFile load(XmlElement node) => SRFile(node);

  @override
  String get tag => "rfile";
}

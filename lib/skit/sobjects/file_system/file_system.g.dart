// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_system.dart';

// **************************************************************************
// SGenGenerator
// **************************************************************************

class SArchiveFactory extends SFactory<SArchive> {
  SArchiveFactory();

  @override
  SArchive load(XmlNode node) => SArchive(node);

  @override
  String get tag => "archive";
}

class SFileFactory extends SFactory<SFile> {
  SFileFactory();

  @override
  SFile load(XmlNode node) => SFile(node);

  @override
  String get tag => "file";
}

class SRArchiveFactory extends SFactory<SRArchive> {
  SRArchiveFactory();

  @override
  SRArchive load(XmlNode node) => SRArchive(node);

  @override
  String get tag => "rarchive";
}

class SRFileFactory extends SFactory<SRFile> {
  SRFileFactory();

  @override
  SRFile load(XmlNode node) => SRFile(node);

  @override
  String get tag => "rfile";
}

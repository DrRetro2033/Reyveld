import 'dart:io';
import 'package:hetu_script/hetu_script.dart';

class HetuAddon {
  final String pathToHetuAddon;
  File get addonFile => File(pathToHetuAddon);
  final Hetu hetu = Hetu();

  HetuAddon(this.pathToHetuAddon) {
    hetu.init();
    hetu.bindExternalFunction("read", _read);
  }

  void _read(int location) {}
}

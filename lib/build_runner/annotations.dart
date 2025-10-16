import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/scripting/sinterface.dart';
import 'package:reyveld/security/certificate/certificate.dart';

class SGen {
  const SGen(this.tag);

  final String tag;
}

class LuaClass<T extends SInterface> {
  final String? name;
  final String description;
  const LuaClass(this.description, {this.name});
}

class LuaFunc {
  final String? name;
  final String? description;
  final bool Function(SCertificate, LuaArgs)? securityCheck;
  const LuaFunc(this.description, {this.name, this.securityCheck});
}

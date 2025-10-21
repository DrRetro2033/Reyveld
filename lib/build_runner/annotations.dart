class SGen {
  const SGen(this.tag);

  final String tag;
}

class LuaClass {
  final String? name;
  final String description;
  const LuaClass(this.description, {this.name});
}

class LuaExport {
  final String? name;
  final String? description;
  final String? securityCheck;
  const LuaExport(this.description, {this.name, this.securityCheck});
}

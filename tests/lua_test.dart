import 'package:arceus/scripting/lua.dart';
import 'package:arceus/skit/skit.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  test("Lua Test", () async {
    final lua = Lua();
    await lua.init();
    lua.addScript("""
skit = SKit.open("C:/Users/Colly/AppData/Roaming/arceus/constellations/Armored Core For Answer.skit")
header = skit.getHeader()
constellation = header.getChild({class="Constellation"})
return constellation.toString()
""");
    final result = await lua.run();
    print(result);
  });
}

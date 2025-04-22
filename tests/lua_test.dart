import 'package:arceus/scripting/lua.dart';
import 'package:arceus/skit/skit.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  test("Lua Test", () async {
    // Lua.logInterface();
    final lua = Lua();
    await lua.init();
    lua.addScript("""
if not SKit.exists("C:/Users/Colly/AppData/Roaming/arceus/constellations/Armored Core For Answer.skit") then 
  skit = SKit.create("C:/Users/Colly/AppData/Roaming/arceus/constellations/Armored Core For Answer.skit", { type = SKitType.constellation })
  constellation = Constellation.new(skit, "Armored Core: For Answer", "C:/Emulation/storage/rpcs3/dev_hdd0/home/00000001/savedata/BLUS30187GAMEDAT000000F5K7M4006");
  skit.getHeader().addChild(constellation)
  files = constellation.getCurrent().getArchive().getFilenames()
  skit.save()
  return files
end
""");
    final result = await lua.run();
    print(result);
  });
}

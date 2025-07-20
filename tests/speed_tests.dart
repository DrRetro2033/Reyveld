import 'dart:io';

import 'package:arceus/scripting/lua.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:arceus/extensions.dart';

const amountOfTests = 512;

typedef SpeedTest = (String, String Function(Directory));

final tests = <SpeedTest>[
  (
    "Creating a Constellation",
    (dir) => """function CreateConstellation(kitPath, name, path)
    local skit : SKit = SKit.create(kitPath, { type = SKitType.constellation, overwrite = true })
    local const : Constellation = Constellation.new(name, path)
    skit.header().addChild(const)
    const.start()
    skit.save()
end

CreateConstellation(
    ":appdata:/arceus/constellations/Test.skit", 
    "Test Constellation",
    "${dir.path.resolvePath()}"
)"""
  ),
  (
    "Growing a Star without Saving",
    (dir) => """function Grow(path, starname)
    local skit = SKit.open(path)
    local const : Constellation = skit.header().getChildByTag(Constellation.tag())
    const.current().grow(starname)
end

Grow(
    ":appdata:/arceus/constellations/Test.skit", 
    "Test Star"
)"""
  ),
  (
    "Creating a Constellation & Growing a Star",
    (dir) => """function CreateConstellation(kitPath, name, path)
    local skit : SKit = SKit.create(kitPath, { type = SKitType.constellation, overwrite = true })
    local const : Constellation = Constellation.new(name, path)
    skit.header().addChild(const)
    const.start()
    skit.save()
end

function Grow(path, starname)
    local skit = SKit.open(path)
    local const : Constellation = skit.header().getChildByTag(Constellation.tag())
    const.current().grow(starname)
    skit.save()
end

CreateConstellation(
    ":appdata:/arceus/constellations/Test.skit", 
    "Test Constellation",
    "${dir.path.resolvePath()}"
)

Grow(
    ":appdata:/arceus/constellations/Test.skit", 
    "Test Star"
)
"""
  ),
];

Future<void> main(List<String> args) async {
  final spin =
      CliSpin(text: "Creating test files...", spinner: CliSpinners.bounce)
          .start();
  final dir = await Directory.systemTemp.createTemp("arceus_test_").then(
      (tempDir) async {
    final testFile = File("${tempDir.path}/test_file_1.txt");
    await testFile.writeAsString("This is a test file.");
    final testFile2 = File("${tempDir.path}/test_file_2.txt");
    await testFile2.writeAsString("This is another test file.");
    spin.success("Test files created at ${tempDir.path}");
    return tempDir;
  }, onError: (e) {
    spin.fail("Failed to create test files: $e");
  });
  final lua = Lua();
  await lua.init();
  for (final test in tests) {
    List<int> times = [];

    final testSpin = CliSpin(
      text: "Running speed test (${test.$1})...",
      suffixText: "(0/$amountOfTests)",
      spinner: CliSpinners.bounce,
    ).start();

    for (var i = 0; i < amountOfTests; i++) {
      await lua.run(test.$2(dir));
      times.add(lua.stopwatch.elapsedMilliseconds);
      testSpin.suffixText = "(${i + 1}/$amountOfTests)";
      // testSpin.render();
    }
    testSpin.suffixText =
        "Avg ${times.reduce((a, b) => a + b) / times.length} ms".skyBlue;
    testSpin.success("Speed test completed! (${test.$1})");
  }

  await dir.delete(recursive: true);
}

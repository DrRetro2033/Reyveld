import 'dart:convert';

import 'package:arceus/extensions.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:glob/glob.dart';

part 'filelist.creators.dart';
part 'filelist.interfaces.dart';
part 'filelist.g.dart';

/// Represents a list of file patterns that can be used to filter files
/// based on their paths. This class supports both whitelisting and blacklisting.
sealed class Globs extends SObject {
  Globs(super._node);

  List<Glob> get globs => utf8
      .decode(base64Decode(innerText!))
      .split("\n")
      .toSet() // Removes duplicates
      .where((e) => e.isNotEmpty)
      .map((e) => Glob(e))
      .toList();
  set globs(List<Glob> value) => innerText =
      base64Encode(utf8.encode(value.map((e) => e.pattern).toSet().join("\n")));

  void add(String pattern) => globs = globs..add(Glob(pattern));

  void addAll(List<String> patterns) =>
      globs = globs..addAll(patterns.map((e) => Glob(e)));

  void remove(String pattern) => globs = globs..remove(Glob(pattern));

  /// Returns a list of filepaths that are allowed by the list.
  List<String> filter(List<String> filepaths) =>
      filepaths.where((f) => included(f)).toList();

  /// Returns true if the filepath is allowed by the list, false if it is not.
  bool included(String filepath);
}

@SGen("whitelist")
final class Whitelist extends Globs {
  Whitelist(super._node);

  @override
  bool included(String filepath) =>
      globs.any((f) => f.matches(filepath.resolvePath().getFilename()));
}

@SGen("blacklist")
final class Blacklist extends Globs {
  Blacklist(super._node);

  @override
  bool included(String filepath) =>
      !globs.any((f) => f.matches(filepath.resolvePath().getFilename()));
}

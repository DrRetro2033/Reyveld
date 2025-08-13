import 'dart:async';
import 'dart:io';
import 'package:arceus/scripting/sinterface.dart';
import 'package:arceus/skit/sobjects/file_system/file_system.dart';
import 'package:rxdart/rxdart.dart';

class DirectoryInterface extends SInterface<Directory> {
  @override
  get className => "Directory";

  @override
  get classDescription => "A directory on the file system.";

  @override
  get statics => {
        LEntry(
          name: "new",
          descr: "Creates a new directory handler.",
          args: const {
            LArg<String>(name: "path", descr: "The path to the directory.")
          },
          returnType: Directory,
          (String path) => Directory(path),
        ),
        LEntry(
          name: "appdata",
          descr:
              "Returns the path to the appdata directory of the current user.",
          args: const {
            LArg<String>(
                name: "relative",
                descr:
                    "Provide a relative path inside the appdata directory to get a specific directory.",
                kind: ArgKind.optionalNamed)
          },
          returnType: Directory,
          ({String relative = ""}) {
            final home = Platform.environment['HOME'] ??
                Platform.environment['USERPROFILE'];
            if (Platform.isMacOS) {
              return Directory('$home/Library/Application Support/$relative');
            } else if (Platform.isLinux) {
              return Directory('$home/.local/share/$relative');
            } else if (Platform.isWindows) {
              final appData = Platform.environment['APPDATA'];
              return Directory('$appData/$relative');
            } else {
              throw UnsupportedError('Unsupported platform');
            }
          },
        ),
        LEntry(
            name: "documents",
            descr: "Returns the path to the documents directory.",
            args: const {
              LArg<String>(
                  name: "relative",
                  descr:
                      "Provide a relative path inside the documents directory to get a specific directory.",
                  kind: ArgKind.optionalNamed)
            },
            returnType: Directory, ({String relative = ""}) {
          final home = Platform.environment['HOME'] ??
              Platform.environment['USERPROFILE'];
          if (Platform.isMacOS || Platform.isLinux) {
            return Directory('$home/Documents/$relative');
          } else if (Platform.isWindows) {
            return Directory(
                '${Platform.environment['USERPROFILE']}/Documents/$relative');
          } else {
            throw UnsupportedError('Unsupported platform');
          }
        }),
      };

  @override
  get exports => {
        LField<String>(
            name: "path",
            descr: "The path to the directory.",
            object?.path ?? ""),
        LEntry(
            name: "list",
            descr:
                "Returns a stream of the files in the directory (files will be of type SFiles).",
            returnType: Stream,
            args: const {
              LArg<bool>(
                  name: "recursive",
                  descr:
                      "Whether to list recursively (i.e. include subdirectories) (default: false).",
                  kind: ArgKind.optionalNamed)
            },
            ({bool recursive = false}) => object!
                    .list(recursive: recursive)
                    .whereType<File>()
                    .transform(StreamTransformer.fromBind((stream) async* {
                  await for (final file in stream) {
                    yield await SFileCreator.open(file.path);
                  }
                }))),
        LEntry(
          name: "exists",
          descr: "Checks if the directory exists.",
          returnType: bool,
          isAsync: true,
          () async => await object!.exists(),
        ),
        LEntry(
            name: "create",
            descr: "Creates the directory.",
            returnType: bool,
            isAsync: true,
            args: const {
              LArg<bool>(
                  name: "recursive",
                  descr: "Whether to create recursively (default: false).",
                  kind: ArgKind.optionalNamed)
            },
            ({bool recursive = false}) async =>
                await object!.create(recursive: recursive)),
        LEntry(
          name: "delete",
          descr: "Deletes the directory.",
          returnType: bool,
          isAsync: true,
          () async => await object!.delete(),
        )
      };
}

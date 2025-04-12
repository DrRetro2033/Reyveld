import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/extensions.dart';
import 'package:arceus/scripting/lua.dart';
import 'package:arceus/skit/skit.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  File lockFile = File(
      "${Arceus.appDataPath}/locks/${Arceus.currentVersion.toString()}.lock");
  if (await isAlreadyRunning(lockFile)) {
    print('Already running');
    exit(0);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 7274);
  print('Server Started');

  await for (HttpRequest request in server) {
    try {
      // This is a check to make sure that the request is for a specific version
      // of Arceus. If the request is for a different version, it will check the current locks in the folder
      // and will ignore the request if the other version and respond with moved permanently.
      // If the other version is not running, it will return a 404 error.
      if (request.uri.pathSegments.join('/') ==
          "${Arceus.currentVersion}/heatbeat") {
        request.response.statusCode = HttpStatus.ok;
        Arceus.talker.info("Checking heatbeat.");
        await request.response.close();
      } else if (request.uri.pathSegments.firstOrNull !=
          Arceus.currentVersion.toString()) {
        await for (final file
            in Directory("${Arceus.appDataPath}/locks").list()) {
          if (file is File) {
            final otherVersion =
                Version.parse(file.path.getFilename(withExtension: false));
            if (otherVersion.toString() ==
                request.uri.pathSegments.firstOrNull) {
              final uri = Uri.http(
                  "127.0.0.1:7274", "${otherVersion.toString()}/heatbeat");
              final response = await http.get(uri);
              if (response.statusCode == 200) {
                request.response.statusCode = HttpStatus.movedPermanently;
                await request.response.close();
              }
              continue;
            }
          }
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        Arceus.talker.error(
            "Version not found. ${request.uri.pathSegments.firstOrNull} not found.");
      } else if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        print('Client connected');
        Arceus.talker.info("Client connected.");
        socket.listen((data) async {
          Arceus.talker.info('Received: $data');
          try {
            final vm = Lua();
            await vm.init();
            vm.addScript(data);
            await vm.run();
          } catch (e, st) {
            print(
                "There was a crash on a request, please check the log folder (${Arceus.appDataPath}/logs) for more information.");
            Arceus.talker.critical("Crash Handler", e, st);
            socket.add("ERROR:$e");
          }
        }, onDone: () {
          print('Client disconnected');
          Arceus.talker.info("Client disconnected.");
          socket.close();
          server.close();
          return;
        }, onError: (error, stack) {
          Arceus.talker.error("Error", error, stack);
        }, cancelOnError: false);
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    } catch (e, st) {
      print(
          "There was a crash on this request, please check the log folder (${Arceus.appDataPath}/logs) for more information.");
      Arceus.talker.critical("Crash Handler", e, st);
    }
  }
  await lockFile.delete();
  exit(0);
}

/// This function checks if the version of this Arceus executable is already running.
/// If it is, it will return true, otherwise it will return false.
Future<bool> isAlreadyRunning(File lockFile) async {
  /// If the file does exist, double check to see if the version has a heartbeat.
  if (await lockFile.exists()) {
    final uri = Uri.http(
        "127.0.0.1:7274", "${Arceus.currentVersion.toString()}/heatbeat");
    try {
      var response = await http.get(uri);
      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      Arceus.talker
          .info("Failed to check heartbeat. Assuming it's not running.");
      return false;
    }
  } else {
    await lockFile.create(recursive: true);
    return false;
  }
}

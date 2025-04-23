import 'dart:async';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/scripting/lua.dart';
import 'package:arceus/skit/skit.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (await isRunning(Arceus.currentVersion)) {
    print('Already running');
    exit(0);
  }
  File lockFile = File(
      "${Arceus.appDataPath}/locks/${Arceus.currentVersion.toString()}.lock");
  await lockFile.create(recursive: true);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 7274);
  print('Server Started');

  Map<String, Lua> sessions = {};

  await for (HttpRequest request in server) {
    final requestUrl = request.uri.pathSegments.sublist(1).join('/');
    try {
      /// Check if the requested version is the same as this program's version.
      if (request.uri.pathSegments.firstOrNull !=
          Arceus.currentVersion.toString()) {
        /// If not, check if the requested version is running.
        if (await isRunning(
            Version.parse(request.uri.pathSegments.firstOrNull!))) {
          /// The requested version is running.
          request.response.statusCode = HttpStatus.movedPermanently;
          await request.response.close();
          continue;
        } else {
          /// The requested version is not running.
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          Arceus.talker.error(
              "Version not found. ${request.uri.pathSegments.firstOrNull} not found.");
          continue;
        }
      }

      if (request.session.isNew) {
        sessions[request.session.id] = Lua();
        await sessions[request.session.id]!.init();
      }

      /// If the requested version is the same as this program's version, continue as normal.
      switch (requestUrl) {
        case "heatbeat":
          request.response.statusCode = HttpStatus.ok;
          Arceus.talker
              .info("Heatbeat checked at ${DateTime.now().toIso8601String()}.");
          await request.response.close();
        case "docs":
          request.response.statusCode = HttpStatus.ok;
          await Lua.generateDocs();
          Arceus.talker.info("Generated docs.");
          await request.response.close();
        default:
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final socket = await WebSocketTransformer.upgrade(request);
            print('Client connected');
            Arceus.talker.info("Client (${request.session.id}) connected.");
            socket.listen((data) async {
              Arceus.talker.info('Received: $data');
              try {
                final result = await sessions[request.session.id]!.run(data);
                socket.add("$result");
              } catch (e, st) {
                print(
                    "There was a crash on this request (Session ID: ${request.session.id}), please check the log folder (${Arceus.appDataPath}/logs) for more information.");
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
Future<bool> isRunning(Version version) async {
  /// If the file does exist, double check to see if the version has a heartbeat.
  File lockFile =
      File("${Arceus.appDataPath}/locks/${version.toString()}.lock");
  if (await lockFile.exists()) {
    final uri = Uri.http("127.0.0.1:7274", "${version.toString()}/heatbeat");
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
    return false;
  }
}

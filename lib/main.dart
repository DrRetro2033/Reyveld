import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arceus/arceus.dart';
import 'package:arceus/scripting/lua.dart';
import 'package:arceus/security/authveld.dart';
import 'package:arceus/skit/skit.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:rxdart/rxdart.dart';
import 'package:version/version.dart';
import 'package:arceus/extensions.dart';
import 'package:http/http.dart' as http;

typedef ArceusSession = (Lua, WebSocket);

Future<void> main(List<String> args) async {
  /// Check if the version of this Arceus executable is already running.
  final isRunningSpinner = CliSpin(spinner: CliSpinners.bounce)
      .start("Checking if running...".skyBlue);
  if (await isRunning(Arceus.version)) {
    isRunningSpinner.fail('Already Running.'.skyBlue);
    exit(0);
  }

  /// The reroute version is the version that
  Version rerouteVersion = await getMostRecentVersion();

  isRunningSpinner.success("Ready to Start!".skyBlue);

  /// If not, create a lock file to indicate that this version of Arceus is running.
  File lockFile =
      File("${Arceus.appDataPath}/locks/${Arceus.version.toString()}.lock");

  final spinner =
      CliSpin(spinner: CliSpinners.bounce).start("Generating Docs...".skyBlue);

  /// Regenerate the lua documentation.
  await Lua.generateDocs().listen((doc) {
    spinner.text = "Generating $doc...".skyBlue;
  }).asFuture();

  spinner.success(
      "Generated Lua Docs at \"${Arceus.appDataPath}/docs/${Arceus.version.toString()}/\""
          .skyBlue);

  /// Verify the signature of the user.
  await Arceus.verifySignature();

  final serverSpinner =
      CliSpin(spinner: CliSpinners.bounce).start("Starting Server...".skyBlue);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 7274);
  serverSpinner.success("Server Started!".skyBlue);

  Map<String, ArceusSession> sessions = {};

  await for (HttpRequest request in server) {
    try {
      Version requestedVersion;

      try {
        requestedVersion = Version.parse(request.uri.pathSegments.first);
      } catch (e) {
        requestedVersion = rerouteVersion;
      }

      /// Check if the requested version is the same as this program's version.
      if (requestedVersion != Arceus.version) {
        /// If not, check if the requested version is running.
        if (await isRunning(requestedVersion)) {
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

      // Has the client requested a specific version?
      bool definedVersion = true;
      try {
        Version.parse(request.uri.pathSegments.first);
      } catch (_) {
        definedVersion = false;
      }
      final requestUrl =
          request.uri.pathSegments.sublist(definedVersion ? 1 : 0).join('/');

      Arceus.talker
          .log("Requested: ${request.method} ${request.uri.toString()}");

      /// If the requested version is the same as this program's version, continue as normal.
      if (request.method == "GET") {
        switch (requestUrl) {
          case "authveld":
            request.response.headers.contentType = ContentType.html;
            request.response.add(
                AuthVeld.authorizePage(request.uri.queryParameters["ticket"]!)
                    .codeUnits);
            await request.response.close();
          case "heartbeat":
            request.response.statusCode = HttpStatus.ok;
            Arceus.talker.info(
                "Heartbeat checked at ${DateTime.now().toIso8601String()}.");
            await request.response.close();
          case "close":
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
            for (final session in sessions.entries) {
              await session.value.$1.awaitForCompletion();
              await session.value.$2
                  .close(WebSocketStatus.goingAway, "Server closed.");
            }
            await server.close();
            exit(0);
          case "lua":
            final id = request.session.id;
            if (WebSocketTransformer.isUpgradeRequest(request)) {
              final socket = await WebSocketTransformer.upgrade(request);
              sessions[id] = (Lua(socket: socket), socket);
              Arceus.printToConsole('Client ($id) connected.'.skyBlue);
              Arceus.talker.info("Client ($id) connected.");
              socket.listen((data) async {
                final requestProgress = CliSpin(spinner: CliSpinners.bounce)
                    .start("Processing request from client ($id)...".aqua);
                Arceus.talker.info("Request from client ($id):\n$data");
                try {
                  await sessions[id]!.$1.init();
                  final result = await sessions[id]!.$1.run(data);
                  socket.add(jsonEncode({
                    "type": "response",
                    "successful": true,
                    "processTime":
                        sessions[id]!.$1.stopwatch.elapsedMilliseconds,
                    "return": result
                  }));
                  requestProgress.success(
                      "Completed request in ${sessions[id]!.$1.stopwatch.elapsedMilliseconds}ms ($id)!"
                          .limeGreen);
                } catch (e, st) {
                  requestProgress.fail(
                      "There was a crash on this request (Session ID: $id), please check the log folder (${Arceus.appDataPath}/logs) for more information."
                          .red);
                  Arceus.talker.critical("Crash Handler", e, st);
                  socket.add(jsonEncode({
                    "type": "response",
                    "successful": false,
                    "processTime":
                        sessions[id]!.$1.stopwatch.elapsedMilliseconds,
                    "return": null
                  }));
                }
              }, onDone: () {
                Arceus.printToConsole('Client ($id) disconnected'.skyBlue);
                Arceus.talker.info("Client ($id) disconnected.");
                socket.close();
                sessions.remove(id);
                return;
              }, onError: (error, stack) {
                Arceus.talker.error("Error", error, stack);
              }, cancelOnError: false);
            } else {
              request.response
                ..statusCode = HttpStatus.forbidden
                ..close();
            }
          case "permissions/details":
            request.response.headers.contentType = ContentType.html;
            request.response.add(
                AuthVeld.getDetailsPage(request.uri.queryParameters["ticket"]!)
                    .codeUnits);
            await request.response.close();
        }
      } else if (request.method == "POST") {
        switch (requestUrl) {
          case "authorize":
            final origin =
                request.headers["origin"] ?? request.headers['referer'];
            if (origin == null || origin.isEmpty) {
              request.response.statusCode = HttpStatus.forbidden;
              await request.response.close();
              continue;
            }
            AuthVeld.authorize(request.uri.queryParameters["ticket"]!);
            request.response.headers.contentType = ContentType.json;
            request.response.add(jsonEncode({"allowed": true}).codeUnits);
            await request.response.close();
          case "deauthorize":
            final origin =
                request.headers["origin"] ?? request.headers['referer'];
            if (origin == null || origin.isEmpty) {
              request.response.statusCode = HttpStatus.forbidden;
              await request.response.close();
              continue;
            }
            AuthVeld.unauthorize(request.uri.queryParameters["ticket"]!);
            request.response.headers.contentType = ContentType.json;
            request.response.add(jsonEncode({"allowed": false}).codeUnits);
            await request.response.close();
        }
      }
    } catch (e, st) {
      Arceus.printToConsole(
          "There was a crash on a websocket, please check the log folder (${Arceus.appDataPath}/logs) for more information."
              .red);
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

Future<Version> getMostRecentVersion() async {
  Directory lockDir = Directory("${Arceus.appDataPath}/locks/");
  Version currentVersion = Arceus.version;
  await for (final lockFile in lockDir.list().whereType<File>()) {
    Version version =
        Version.parse(lockFile.path.getFilename(withExtension: false));
    if (currentVersion.compareTo(version) > 0) {
      currentVersion = version;
    }
  }
  return currentVersion;
}

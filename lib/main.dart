import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/event.dart';
import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/security/authveld.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:rxdart/rxdart.dart';
import 'package:version/version.dart';
import 'package:reyveld/extensions.dart';
import 'package:http/http.dart' as http;

typedef ReyveldSession = (Lua, WebSocket);

Future<void> main(List<String> args) async {
  /// Check if the version of this Reyveld executable is already running.
  final isRunningSpinner = CliSpin(spinner: CliSpinners.bounce)
      .start("Checking if running...".skyBlue);
  if (await isRunning(Reyveld.version)) {
    isRunningSpinner.fail('Already Running.'.skyBlue);
    exit(0);
  }

  final parser = ArgParser();
  parser.addFlag("verbose", abbr: "v", help: "Run Arceus in verbose mode.");
  final results = parser.parse(args);
  Reyveld.verbose = results.flag("verbose");

  /// The reroute version is the version that this Reyveld executable is rerouting to.
  Version rerouteVersion = await getMostRecentVersion();

  isRunningSpinner.success("Ready to Start!".skyBlue);

  /// If not, create a lock file to indicate that this version of Reyveld is running.
  File lockFile =
      File("${Reyveld.appDataPath}/locks/${Reyveld.version.toString()}.lock");

  final spinner =
      CliSpin(spinner: CliSpinners.bounce).start("Generating Docs...".skyBlue);

  /// Regenerate the lua documentation.
  await Lua.generateDocs().listen((doc) {
    spinner.text = "Generating $doc...".skyBlue;
  }).asFuture();

  spinner.success(
      "Generated Lua Docs at \"${Reyveld.appDataPath}/docs/${Reyveld.version.toString()}/\""
          .skyBlue);

  /// Verify the signature of the user.
  await Reyveld.verifySignature();

  final serverSpinner =
      CliSpin(spinner: CliSpinners.bounce).start("Starting Server...".skyBlue);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 7274);
  serverSpinner.success("Server Started!".skyBlue);

  Map<String, ReyveldSession> sessions = {};

  await for (HttpRequest request in server) {
    try {
      Version requestedVersion;

      try {
        requestedVersion = Version.parse(request.uri.pathSegments.first);
      } catch (e) {
        requestedVersion = rerouteVersion;
      }

      /// Check if the requested version is the same as this program's version.
      if (requestedVersion != Reyveld.version) {
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
          Reyveld.talker.error(
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
            Reyveld.talker.verbose(
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

            /// We save the client's session ID here, as once the Garbage Collector collects the request, the ID will be gone as well.
            final id = request.session.id;
            if (WebSocketTransformer.isUpgradeRequest(request)) {
              final socket = await WebSocketTransformer.upgrade(request);
              sessions[id] = (Lua(socket: socket), socket);
              Reyveld.printToConsole('(SID:$id) Client connected.'.skyBlue);
              Reyveld.talker.info("(SID:$id) Client connected.");
              socket.listen((data) async {
                try {
                  /// Run the request and get the result.
                  Reyveld.talker.info("(SID:$id) Received request.");
                  Reyveld.talker.verbose("(SID:$id) Request: $data");
                  final result = await sessions[id]!.$1.run(data);
                  socket.add(SocketEvent.completed(result.result,
                          pid: result.processId ?? "")
                      .toString());
                  Reyveld.talker.info(
                      "(SID:$id, PID:${result.processId ?? ""}) Completed request.");
                } catch (e, st) {
                  Reyveld.talker.critical("Crash Handler", e, st);
                  socket.add(SocketEvent.error(e).toString());
                }
              }, onDone: () {
                Reyveld.printToConsole('(SID:$id) Client disconnected'.skyBlue);
                Reyveld.talker.info("(SID:$id) Client disconnected.");
                socket.close();
                sessions.remove(id);
                return;
              }, onError: (error, stack) {
                Reyveld.talker.error("Error", error, stack);
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
      Reyveld.printToConsole(
          "There was a crash on a websocket, please check the log folder (${Reyveld.appDataPath}/logs) for more information."
              .red);
      Reyveld.talker.critical("Crash Handler", e, st);
    }
  }
  await lockFile.delete();
  exit(0);
}

/// This function checks if the version of this Reyveld executable is already running.
/// If it is, it will return true, otherwise it will return false.
Future<bool> isRunning(Version version) async {
  /// If the file does exist, double check to see if the version has a heartbeat.
  File lockFile =
      File("${Reyveld.appDataPath}/locks/${version.toString()}.lock");
  if (await lockFile.exists()) {
    final uri = Uri.http("127.0.0.1:7274", "${version.toString()}/heatbeat");
    try {
      var response = await http.get(uri);
      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      Reyveld.talker
          .info("Failed to check heartbeat. Assuming it's not running.");
      return false;
    }
  } else {
    return false;
  }
}

Future<Version> getMostRecentVersion() async {
  Directory lockDir = Directory("${Reyveld.appDataPath}/locks/");
  if (!await lockDir.exists()) {
    await lockDir.create(recursive: true);
  }
  Version currentVersion = Reyveld.version;
  await for (final lockFile in lockDir.list().whereType<File>()) {
    Version version =
        Version.parse(lockFile.path.getFilename(withExtension: false));
    if (currentVersion.compareTo(version) > 0) {
      currentVersion = version;
    }
  }
  return currentVersion;
}

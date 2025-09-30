import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pool/pool.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/event.dart';
import 'package:reyveld/scripting/lua.dart';
import 'package:reyveld/security/authveld.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:rxdart/rxdart.dart';
import 'package:version/version.dart';
import 'package:reyveld/extensions.dart';
import 'package:reyveld/extras.dart';
import 'package:http/http.dart' as http;

typedef ReyveldSession = (Lua, WebSocket);

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser.addFlag("verbose", abbr: "v", help: "Run Arceus in verbose mode.");
  parser.addOption("script",
      abbr: "s",
      help: "Run a single lua script inside of Reyveld. (NOT RECOMMENDED!)");
  parser.addOption("certificate",
      abbr: "c",
      help:
          "The script certificate token to use for authentication. (NOT RECOMMENDED!)");
  final results = parser.parse(args);
  Reyveld.verbose = results.flag("verbose");

  final script = results.option("script");
  final scriptCertificate =
      await AuthVeld.loadCertificate(results.option("certificate") ?? "");

  if (script != null) {
    final file = File(script);
    if (!await file.exists()) {
      Reyveld.printToConsole("Script '$script' does not exist. Exiting.");
      exit(1);
    }
    final content = await file.readAsString();
    try {
      final r = await Lua(certificate: scriptCertificate).run(content);
      Reyveld.printToConsole(SocketEvent.completed(r.result));
      exit(0);
    } catch (e) {
      Reyveld.printToConsole(SocketEvent.error(e));
      exit(1);
    }
  }

  /// Check if the version of this Reyveld executable is already running.
  Reyveld.talker.verbose("Arceus is in verbose mode.");
  final isRunningSpinner = CliSpin(spinner: CliSpinners.bounce)
      .start("Checking if running...".skyBlue);

  if (await isRunning(Reyveld.version)) {
    isRunningSpinner.fail(
        'Already running version "${Reyveld.version.toString()}".'.skyBlue);
    exit(0);
  }

  /// The reroute version is the version that this Reyveld executable is rerouting to.
  Version rerouteVersion = await getMostRecentVersion();

  isRunningSpinner.success("Ready to Start!".skyBlue);

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

  await Reyveld.deleteTempFiles();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 7274);
  serverSpinner.success("Server Started!".skyBlue);

  if (await Reyveld.getOtherOption("DISABLE_WELCOME_MESSAGE") != "True") {
    Reyveld.printToConsole("""
Dear user/developer,
  Thank you for using Reyveld! ❤️

  Reyveld is a passion project created by me to make a diverse set of tools for working with files.
As someone who has been making random scripts to read Pokémon files, resize textures for Titanfall 2, 
and sift through Source Engine demo files; I wanted a toolbox that didn't need a bunch of boilerplate code,
or multiple dependencies to get started. That's why Reyveld is only a single executable! It's all under one 
roof, and it's easy to use! No more installing Python or Java just to do a simple task!

  Reyveld will always be free and open source, however, if you want to support me to continue developing Reyveld, 
consider sponsoring me on GitHub. Every single dollar is appreciated!

  If you do not know what you are doing, you can read more about Reyveld here: 
https://github.com/DrRetro2033/Reyveld.

  If you have any problems, questions, or suggestions; Please feel free to open an issue on GitHub: 
https://github.com/DrRetro2033/Reyveld/issues/new.

  If you want to support the development of Reyveld, you can consider sponsoring me on GitHub: 
https://github.com/sponsors/DrRetro2033.

Sincerely,
DrRetro2033 - Creator of Reyveld.

P.S. If you want to disable this message, you can go to ${Reyveld.appDataPath}/config.ini and set 
"DISABLE_WELCOME_MESSAGE" to "1", in the "other" section.
"""
        .orange);
  }

  Map<String, ReyveldSession> sessions = {};
  Pool luaPool = Pool(int.parse(await Reyveld.getPerformanceOption("LUAPOOL")),
      timeout: parseDurationFromString(
          await Reyveld.getPerformanceOption("LUAPOOL_TIMEOUT")));

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

      Reyveld.talker.verbose("Request: $requestUrl; ${request.method}");

      /// If the requested version is the same as this program's version, continue as normal.
      if (request.method == "GET") {
        switch (requestUrl) {
          case "authveld":
            request.response.headers.contentType = ContentType.html;
            if (!request.uri.queryParameters.containsKey("ticket")) {
              request.response.statusCode = HttpStatus.badRequest;
              await request.response.close();
              continue;
            }
            request.response.add(
                AuthVeld.authorizePage(request.uri.queryParameters["ticket"]!)
                    .codeUnits);
            await request.response.close();
          case "heartbeat":
            request.response.statusCode = HttpStatus.ok;
            request.response.add("OK".codeUnits);
            Reyveld.talker.verbose(
                "Heartbeat checked at ${DateTime.now().toIso8601String()}.");
            await request.response.close();
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
                  Reyveld.talker.verbose("(SID:$id) Received request.");
                  Reyveld.talker.verbose("(SID:$id) Request:\n$data");
                  final result = await luaPool.withResource(
                      () async => await sessions[id]!.$1.run(data));
                  socket.add(SocketEvent.completed(result.result,
                          pid: result.processId ?? "")
                      .toString());
                  Reyveld.talker.verbose(
                      "(SID:$id, PID:${result.processId ?? ""}) Completed request.");
                } catch (e, st) {
                  Reyveld.printToConsole(
                      "There was a crash on a request, please check the log folder (${Reyveld.appDataPath}/logs) for more information."
                          .red);
                  socket.add(SocketEvent.error(e).toString());
                  Reyveld.talker.error("(SID:$id)", e, st);
                }
              }, onDone: () {
                Reyveld.printToConsole('(SID:$id) Client disconnected'.skyBlue);
                Reyveld.talker.info("(SID:$id) Client disconnected.");
                socket.close();
                sessions.remove(id);
                return;
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
          default:
            request.response.statusCode = HttpStatus.notFound;
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
          default:
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
        }
      } else if (request.method == "OPTIONS") {
        switch (requestUrl) {
          case "close":
            for (final session in sessions.entries) {
              await session.value.$1.awaitForCompletion().then((_) async {
                await session.value.$2
                    .close(WebSocketStatus.goingAway, "Server closed.");
              });
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.add(jsonEncode({}).codeUnits);
            await request.response.close();
            await server.close();
            await Reyveld.deleteTempFiles();
            exit(0);
          default:
            request.response.statusCode = HttpStatus.notFound;
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
    final uri = Uri.http("127.0.0.1:7274", "${version.toString()}/heartbeat");
    Reyveld.talker.verbose("Checking for Heartbeat at '$uri'.");
    try {
      final response = await http.get(uri);
      Reyveld.talker.verbose("Heartbeat response: ${response.statusCode}");
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

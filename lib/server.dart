import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pool/pool.dart';
import '/reyveld.dart';
import '/event.dart';
import '/scripting/lua.dart';
import '/security/authveld.dart';
import 'package:chalkdart/chalkstrings.dart';
import 'package:cli_spin/cli_spin.dart';
import '/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:version/version.dart';
import '/extensions.dart';
import '/extras.dart';
import 'package:http/http.dart' as http;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

typedef ReyveldSession = (Lua, WebSocket);

Future<void> runServer() async {
  /// Check if the version of this Reyveld executable is already running.
  Reyveld.talker.verbose("Reyveld is in verbose mode.");
  final isRunningSpinner = CliSpin(spinner: CliSpinners.bounce)
      .start("Checking if running...".skyBlue);

  if (await isRunning(Reyveld.version)) {
    isRunningSpinner.fail(
        'Already running version "${Reyveld.version.toString()}".'.skyBlue);
    exit(0);
  }

  isRunningSpinner.success("Ready to Start!".skyBlue);

  File lockFile = File(Reyveld.lockFilePath);

  final serverSpinner =
      CliSpin(spinner: CliSpinners.bounce).start("Starting Server...".skyBlue);

  await Reyveld.deleteTempFiles();
  Pool luaPool = Pool(int.parse(await Reyveld.getPerformanceOption("LUAPOOL")),
      timeout: parseDurationFromString(
          await Reyveld.getPerformanceOption("LUAPOOL_TIMEOUT")));

  HttpServer? server;

  final app = Router();

  app.get("/authveld", (Request request) async {
    if (!request.url.queryParameters.containsKey("ticket")) {
      return Response.badRequest(body: "No ticket provided.");
    }
    return Response.ok(
        AuthVeld.authorizePage(request.url.queryParameters["ticket"]!)
            .codeUnits,
        headers: {"Content-Type": "text/html"});
  });

  app.get("/heartbeat", (Request request) async {
    Reyveld.talker
        .verbose("Heartbeat checked at ${DateTime.now().toIso8601String()}.");
    return Response.ok("OK".codeUnits);
  });

  app.get('/lua', webSocketHandler((webSocket, _) {
    final id = generateUUID();
    final lua = Lua(socket: webSocket);
    Reyveld.printToConsole("(SID:$id) Client connected.".skyBlue);
    Reyveld.talker.verbose("(SID:$id) Client connected.");
    // Listen for incoming messages
    webSocket.stream.listen((data) async {
      try {
        Reyveld.talker.verbose("(SID:$id) Received data:\n$data");
        final result =
            await luaPool.withResource(() async => await lua.run(data));
        Reyveld.talker
            .info("(SID:$id, PID:${result.processId ?? ""}) Result: $result");
        webSocket.sink.add(
            SocketEvent.completed(result.result, pid: result.processId ?? "")
                .toString());
      } catch (e, st) {
        Reyveld.printToConsole(
            "There was a crash on a websocket, please check the log folder (${Reyveld.logsPath}) for more information."
                .red);
        webSocket.sink.add(SocketEvent.error(e).toString());
        Reyveld.talker.error("(SID:$id)", e, st);
      }
    }, onError: (e) {
      Reyveld.printToConsole(
          "There was a crash on a websocket, please check the log folder (${Reyveld.logsPath}) for more information."
              .red);
      Reyveld.talker.error("(SID:$id)", e);
    }, onDone: () {
      Reyveld.printToConsole("(SID:$id) Client disconnected.".orange);
      Reyveld.talker.verbose("(SID:$id) Client disconnected.");
    });
  }));

  app.get("/permissions/details", (Request request) async {
    if (!request.url.queryParameters.containsKey("ticket")) {
      return Response.badRequest(body: "No ticket provided.");
    }
    return Response.ok(
        AuthVeld.getDetailsPage(request.url.queryParameters["ticket"]!)
            .codeUnits,
        headers: {"Content-Type": "text/html"});
  });

  app.post("/authorize", (Request request) async {
    final origin = request.headers["origin"] ?? request.headers['referer'];
    if (origin == null || origin.isEmpty) {
      return Response.forbidden("No origin provided in request.");
    }
    Reyveld.talker.info("Origin for authorization: $origin");
    // if (origin != Reyveld.origi) {
    //   return Response.forbidden("Invalid origin.");
    // }

    await AuthVeld.acceptTicket(request.url.queryParameters["ticket"]!);

    return Response.ok(jsonEncode({"allowed": true}).codeUnits);
  });

  app.post("/deauthorize", (Request request) async {
    final origin = request.headers["origin"] ?? request.headers['referer'];
    if (origin == null || origin.isEmpty) {
      return Response.forbidden("No origin provided in request.");
    }

    await AuthVeld.rejectTicket(request.url.queryParameters["ticket"]!);

    return Response.ok(jsonEncode({"allowed": true}).codeUnits);
  });

  final versionRedirect = createMiddleware(requestHandler: rerouteVersion);

  final handler =
      const Pipeline().addMiddleware(versionRedirect).addHandler(app.call);

  server = await io.serve(handler, "127.0.0.1", 7274);

  serverSpinner.success("Server Started!".skyBlue);
}

/// This function checks if the version of this Reyveld executable is already running.
///
/// If it is, it will return true, otherwise it will return false.
Future<bool> isRunning(Version version) async {
  /// If the file does exist, double check to see if the version has a heartbeat.
  File lockFile = File(Reyveld.lockFilePath);
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
  Directory lockDir = Directory(Reyveld.locksPath);
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

/// This function reroutes a request to the most recent version, or the requested version if it exists.
///
/// For example, if there are two versions of Reyveld running, lets say 1.0.0 and 1.0.1, and the request doesn't specify a version;
/// then by default it will reroute to the most recent version, which is 1.0.1.
///
/// If the request does specify a version, then it attempt to reroute to that version, however it must be running for it to be rerouted.
Future<Response?> rerouteVersion(Request request) async {
  Version requestedVersion;
  Version defaultVersion = await getMostRecentVersion();

  // Has the client requested a specific version?
  bool definedVersion = true;
  try {
    requestedVersion = Version.parse(request.url.pathSegments.first);
  } catch (_) {
    definedVersion = false;
    requestedVersion = defaultVersion;
  }

  /// Check if the requested version is the same as this program's version.
  if (requestedVersion != Reyveld.version) {
    /// If not, check if the requested version is running.
    if (await isRunning(requestedVersion)) {
      /// The requested version is running.
      return Response.movedPermanently(request.url);
    } else {
      /// The requested version is not running.
      Reyveld.talker.error(
          "Version not found. ${request.url.pathSegments.firstOrNull} not found.");
      return Response.notFound(request.url);
    }
  }

  final requestUrl =
      request.url.pathSegments.sublist(definedVersion ? 1 : 0).join('/');

  request.change(path: requestUrl);

  return null;
}

import 'dart:convert';
import 'dart:io';
import 'package:arceus/extensions.dart';
import 'package:arceus/scripting/feature_sets/feature_sets.dart';
import 'package:arceus/version_control/constellation.dart';
import 'package:arceus/version_control/plasma.dart';
import 'package:talker/talker.dart';

/// # `class` `ArceusServer`
/// ## A class that will create a local server for application integration.
class ArceusServer {
  static const bt = 7274; // Default port number.
  static Talker talker = Talker();

  final Map<String, ServerCommand> _commands = {};

  /// # `void` `start`
  /// ## Starts the server
  Future<void> start() async {
    /// 2. Uphold the Mission
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, bt);
    talker.log(
        "Server running on http://${server.address.address}:${server.port}");

    /// 3. Protect the Pilot
    await for (HttpRequest request in server) {
      final stop = await _processRequest(request);
      if (stop) {
        break;
      }
    }
    await server.close();
  }

  ArceusServer() {
    addCommand(ConstellationCommands());
    addCommand(ReadCommand());
  }

  void addCommand(ServerCommand command) {
    if (_commands.containsKey(command.name)) {
      throw Exception("Command ${command.name} already exists.");
    }
    _commands[command.name] = command;
  }

  /// # `Future<void>` `_processRequest`
  /// ## Processes the requests from a client.
  Future<bool> _processRequest(HttpRequest request) async {
    talker.info("Got request for ${request.uri.path}.");
    final response = request.response;
    try {
      switch (request.uri.path) {
        case '/stop':
          return true;
        case '/':
          response
            ..statusCode = HttpStatus.ok
            ..write('Hello from Arceus!');
          break;
        default:
          bool successful = false;
          if (request.uri.pathSegments.isNotEmpty) {
            final initPath = request.uri.pathSegments.first;

            if (_commands.containsKey(initPath)) {
              await _commands[initPath]!
                  .run(request, request.uri.pathSegments.sublist(1));
              successful = true;
            }
          }
          if (!successful) {
            talker.error("Unknown Path ${request.uri.path}");
            // Handle unknown paths
            response
              ..statusCode = HttpStatus.notFound
              ..write('Not Found');
          }

          break;
      }
    } catch (e, st) {
      talker.handle(e, st, "Error in Server");
      response.statusCode = HttpStatus.badRequest;
    }
    response.close();
    return false;
  }
}

abstract class ServerCommand {
  String get name;
  final Map<String, ServerCommand> _commands = {};

  List<String> get _requiredArgsOnDirectCall => [];

  List<String> get _requiredArgsOnIndirectCall => [];

  /// # `void` addSubCommand(ServerCommand command)
  /// ## Adds a subcommand to the command.
  /// If a command with the same name already exists, an [Exception] is thrown.
  void addSubCommand(ServerCommand command) {
    if (_commands.containsKey(command.name)) {
      throw Exception("Command ${command.name} already exists.");
    }
    _commands[command.name] = command;
  }

  Future<void> onDirectCall(
          HttpRequest request, HttpResponse response, Talker talker) =>
      Future.value();

  Future<dynamic> onIndirectCall(HttpRequest request) => Future.value();

  Future<void> run(HttpRequest request, List<String> pathContinued,
      {dynamic other}) async {
    if (pathContinued.isEmpty) {
      if (_requiredArgsOnDirectCall.isNotEmpty) {
        bool check = true;
        for (String arg in _requiredArgsOnDirectCall) {
          if (!request.uri.queryParameters.containsKey(arg)) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write('Error: Missing "$arg" query parameter.')
              ..close();
            ArceusServer.talker.error("Error: Missing '$arg' query parameter.");
            check = false;
          }
        }
        if (!check) {
          return Future.value();
        }
      }
      return await onDirectCall(request, request.response, ArceusServer.talker);
    } else {
      if (_requiredArgsOnIndirectCall.isNotEmpty) {
        bool check = true;
        for (String arg in _requiredArgsOnDirectCall) {
          if (!request.uri.queryParameters.containsKey(arg)) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write('Error: Missing "$arg" query parameter.')
              ..close();
            ArceusServer.talker.error("Error: Missing '$arg' query parameter.");
            check = false;
          }
        }
        if (!check) {
          return Future.value();
        }
      }
      return await _commands[pathContinued.first]!.run(
          request, pathContinued.sublist(1),
          other: await onIndirectCall(request));
    }
  }
}

class ConstellationCommands extends ServerCommand {
  @override
  String get name => 'constellation';

  @override
  Future<dynamic> onIndirectCall(HttpRequest request) async {
    final path = request.uri.queryParameters['path'];
    if (path == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Error: Missing "path" query parameter.')
        ..close();
      ArceusServer.talker.error("Error: Missing 'path' query parameter.");
    }
  }

  ConstellationCommands() {
    addSubCommand(ConstellationExists());
  }
}

class ConstellationExists extends ServerCommand {
  @override
  String get name => 'exists';

  @override
  Future<void> onDirectCall(
      HttpRequest request, HttpResponse response, Talker talker) async {
    final constPath = request.uri.queryParameters['path']!;
    final result = Constellation.exists(constPath);
    response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({"path": constPath.getFilename(), "result": result}));
  }
}

class StarmapCommand extends ServerCommand {
  @override
  String get name => 'starmap';

  @override
  Future<void> onDirectCall(
      HttpRequest request, HttpResponse response, Talker talker) async {
    final constPath = request.uri.queryParameters['path']!;
    if (!Constellation.exists(constPath)) {
      response
        ..statusCode = HttpStatus.badRequest
        ..write('Error: Constellation does not exist at path! "$constPath"')
        ..close();
      talker.error('Error: Constellation does not exist at path! "$constPath"');
      return;
    }
    final result = Constellation(path: constPath).starmap.toJson();
    response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({"path": constPath.getFilename(), "result": result}));
  }
}

class ReadCommand extends ServerCommand {
  @override
  List<String> get _requiredArgsOnDirectCall => ['path'];

  @override
  String get name => 'read';

  @override
  Future<void> onDirectCall(
      HttpRequest request, HttpResponse response, Talker talker) async {
    final filePath = request.uri.queryParameters['path']!;

    final addonPath = request.uri.queryParameters.containsKey('addon')
        ? request.uri.queryParameters['addon']
        : null;

    // Call the function with the extracted path.
    ReadResult result =
        Plasma.fromFile(File(filePath)).readWithAddon(addonPath: addonPath)!;
    response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({
        "filename": filePath.getFilename(),
        "result": result.data,
        "checks": result.checks
      }));
  }
}

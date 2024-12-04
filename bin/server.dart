import 'dart:io';
import 'package:talker/talker.dart';
import './scripting/addon.dart';
import './cli.dart';

/// # `class` `ArceusServer`
/// ## A class that will create a local server for application integration.
class ArceusServer {
  static Talker talker = Talker();

  /// # final `KeyboardInput` keyboard
  /// ## The keyboard input handler.
  static final keyboard = KeyboardInput();

  /// # `void` `start`
  /// ## Starts the server
  static Future<void> start() async {
    keyboard.onKeyPress.listen((key) {
      if (key.char == 'q') {
        exit(0);
      }
    });
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 7274);
    talker.log(
        "Server running on http://${server.address.address}:${server.port}");
    await for (HttpRequest request in server) {
      final stop = await _processRequest(request);
      if (stop) {
        break;
      }
    }
    await server.close();
  }

  /// # `Future<void>` `_processRequest`
  /// ## Processes the requests from the client.
  static Future<bool> _processRequest(HttpRequest request) async {
    talker.info("Got request for ${request.uri.path}.");
    final response = request.response;
    try {
      switch (request.uri.path) {
        // case '/read':
        //   // Get the 'path' query parameter
        //   final filePath = request.uri.queryParameters['path'];

        //   if (filePath == null) {
        //     response
        //       ..statusCode = HttpStatus.badRequest
        //       ..write('Error: Missing "path" query parameter')
        //       ..close();
        //     talker.error("Error: Missing 'path' query parameter");
        //   } else {
        //     // Call the function with the extracted path
        //     dynamic result =
        //         PatternAddon.getAssoiatedAddon(filePath).read(filePath);
        //     response
        //       ..statusCode = HttpStatus.ok
        //       ..write(result);
        //   }
        //   break;
        case '/stop':
          return true;
        case '/':
          response
            ..statusCode = HttpStatus.ok
            ..write('Hello from Arceus!');
        default:
          talker.error("Unknown Path ${request.uri.path}");
          // Handle unknown paths
          response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
      }
    } catch (e, st) {
      talker.handle(e, st, "Error in Server");
      response.statusCode = HttpStatus.badRequest;
    }
    response.close();
    return false;
  }
}

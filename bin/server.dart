import 'dart:io';
import 'package:talker/talker.dart';
import './scripting/addon.dart';

/// # `class` `ArceusServer`
/// ## A class that will create a local server for application integration.
class ArceusServer {
  static Talker talker = Talker();

  static void start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 7274);
    talker.log(
        "Server running on http://${server.address.address}:${server.port}");
    await for (HttpRequest request in server) {
      _processRequest(request);
    }
  }

  static Future<void> _processRequest(HttpRequest request) async {
    talker.info("Got request for ${request.uri.path}.");
    final response = request.response;
    try {
      switch (request.uri.path) {
        case '/read':
          // Get the 'path' query parameter
          final filePath = request.uri.queryParameters['path'];

          if (filePath == null) {
            response
              ..statusCode = HttpStatus.badRequest
              ..write('Error: Missing "path" query parameter')
              ..close();
          } else {
            // Call the function with the extracted path
            dynamic result =
                PatternAddon.getAssoiatedAddon(filePath).read(filePath);
            response
              ..statusCode = HttpStatus.ok
              ..write(result);
          }
          break;
        default:
          talker.error("Unknown Path");
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
  }
}

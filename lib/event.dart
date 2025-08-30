import 'dart:convert';

enum EventType {
  starting,
  completed,
  data,
  error,
}

/// This class formats events to be sent to the client, with a timestamp and process id included.
class SocketEvent {
  final EventType type;
  final String processId;
  final dynamic data;
  final DateTime timestamp;

  SocketEvent(this.type, this.data, {this.processId = ""})
      : timestamp = DateTime.now();

  factory SocketEvent.completed(dynamic data, {String pid = ""}) =>
      SocketEvent(EventType.completed, data, processId: pid);

  factory SocketEvent.data(dynamic data, {String pid = ""}) =>
      SocketEvent(EventType.data, data, processId: pid);

  factory SocketEvent.error(Object exception, {String pid = ""}) =>
      SocketEvent(EventType.error, exception.toString(), processId: pid);

  @override
  String toString() => jsonEncode({
        "type": type.name,
        "processId": processId,
        "timestamp": timestamp.toIso8601String(),
        "data": data
      });
}

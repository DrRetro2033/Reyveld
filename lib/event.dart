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

  SocketEvent(this.type, this.processId, this.data)
      : timestamp = DateTime.now();

  factory SocketEvent.starting(String id, String code) =>
      SocketEvent(EventType.starting, id, code);

  factory SocketEvent.completed(String id, dynamic data) =>
      SocketEvent(EventType.completed, id, data);

  factory SocketEvent.data(String id, dynamic data) =>
      SocketEvent(EventType.data, id, data);

  factory SocketEvent.error(String id, Object exception) =>
      SocketEvent(EventType.error, id, exception.toString());

  @override
  String toString() => jsonEncode({
        "type": type.name,
        "processId": processId,
        "timestamp": timestamp.toIso8601String(),
        "data": data
      });
}

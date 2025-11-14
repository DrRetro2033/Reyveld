import 'package:reyveld/security/policies/policy.dart';

/// Repersents a ticket for authorizing an application wanting to use Reyveld.
/// The ticket contains its own unique id, the application name, and the permissions the application wants to use.
class AuthorizeTicket {
  /// The unique id of the ticket.
  final String ticket;

  /// The name of the application that is requesting authorization.
  final String applicationName;

  /// The policies that the application is requesting.
  final List<SPolicy> policies;

  /// The token that will be given to the application if it's authorized.
  String? token;

  AuthorizeTicket(this.ticket, this.applicationName, this.policies);

  @override
  int get hashCode => ticket.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AuthorizeTicket && other.ticket == ticket;
}

extension AuthorizationTicketList on Set<AuthorizeTicket> {
  AuthorizeTicket? operator [](String ticket) {
    for (final t in this) {
      if (t.ticket == ticket) return t;
    }
    return null;
  }
}

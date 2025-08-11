import 'package:arceus/security/policies/policy.dart';

/// Repersents a ticket for authorizing an application wanting to use Arceus.
/// The ticket contains its own unique id, the application name, and the permissions the application wants to use.
class AuthorizeTicket {
  final String ticket;
  final String applicationName;
  final List<SPolicy> policies;

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

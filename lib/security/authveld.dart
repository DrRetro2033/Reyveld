import 'dart:async';
import 'dart:math';

import 'package:arceus/scripting/sinterface.dart';
import 'package:arceus/security/authorize_ticket.dart';
import 'package:arceus/security/policies/policy.dart';
import 'package:open_url/open_url.dart';
import 'package:xml/xml.dart';

part 'authveld.interface.dart';
part 'authveld.website.dart';

typedef AuthorizeEvent = (AuthorizeTicket, bool);

class AuthVeld {
  static final Set<AuthorizeTicket> _authorizationTickets = {};

  static final StreamController<AuthorizeEvent> _authorizationController =
      StreamController.broadcast();

  static Future<String?> getAuthorization(
      String name, List<SPolicy> permissions) async {
    final ticket = AuthorizeTicket(generateToken(), name, permissions);
    _authorizationTickets.add(ticket);
    await openUrl(
        "http://127.0.0.1:7274/authveld?ticket=${Uri.encodeQueryComponent(ticket.ticket)}");
    await for (final event in _authorizationController.stream) {
      if (event.$1 == ticket) {
        if (event.$2) return ticket.ticket;
        return null;
      }
    }
    return null;
  }

  static void authorize(String tokenToAuthorize) {
    final ticket = _authorizationTickets[tokenToAuthorize];
    if (ticket == null) return;
    _authorizationController.add((ticket, true));
    _authorizationTickets.remove(ticket);
  }

  static void unauthorize(String tokenToUnauthorize) {
    final ticket = _authorizationTickets[tokenToUnauthorize];
    if (ticket == null) return;
    _authorizationController.add((ticket, false));
    _authorizationTickets.remove(ticket);
  }

  /// Generates an authorization page for the given application.
  ///
  /// This page prompts the user to grant or deny access to the application
  /// with the specified permissions. It creates an authorization ticket
  /// and adds it to the list of authorization tickets.
  ///
  /// Returns a string representing the HTML content of the authorization page.
  ///
  /// - Parameters:
  ///   - applicationName: The name of the application requesting access.
  ///   - permissionToken: The token associated with the permission request.
  ///   - permissions: A set of permissions the application is requesting.

  static String authorizePage(String ticket) {
    final t = _authorizationTickets[ticket];
    if (t == null) return expiredTicketPage;
    return buildAuthPage(
      t.applicationName,
      t.ticket,
      t.policies,
    );
  }

  static String generateToken([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  static String getDetailsPage(String ticketId) {
    final XmlBuilder builder = XmlBuilder();
    builder.doctype('html');
    builder.element('html', nest: () {
      builder.attribute('lang', 'en');
      builder.xml("""<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <style>
        body {
            margin: 0;
            background: #181a1b;
            font-family: sans-serif;
            height: 100vh;
            display: flex;
            align-items: left;
            justify-content: left;
            text-align: left;
            color: white;
        }
    </style>
</head>""");
      builder.element('body', nest: () {
        builder.element('h1', nest: () {
          builder.text('Your Ticket ID is: $ticketId');
        });
      });
    });
    return builder.buildDocument().toXmlString(pretty: true, newLine: "\n");
  }
}

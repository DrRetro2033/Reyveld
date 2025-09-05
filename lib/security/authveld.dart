import 'dart:async';
import 'dart:math';

import 'package:reyveld/reyveld.dart';
import 'package:reyveld/security/authorize_ticket.dart';
import 'package:reyveld/security/certificate/certificate.dart';
import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/skit/skit.dart';
import 'package:open_url/open_url.dart';

part 'authveld.interface.dart';
part 'authveld.website.dart';

typedef AuthorizeEvent = (AuthorizeTicket, bool);

class AuthVeld {
  static final SKit _kit = SKit("${Reyveld.appDataPath}/authveld.skit");

  static final Set<AuthorizeTicket> _authorizationTickets = {};

  static final StreamController<AuthorizeEvent> _authorizationController =
      StreamController.broadcast();

  static Future<String?> getAuthorization(
      String name, List<SPolicy> permissions) async {
    final ticket = AuthorizeTicket(generateTicketID(), name, permissions);
    _authorizationTickets.add(ticket);
    await openUrl(
        "http://127.0.0.1:7274/authveld?ticket=${Uri.encodeQueryComponent(ticket.ticket)}");
    await for (final event in _authorizationController.stream) {
      if (event.$1 == ticket) {
        if (event.$2) return ticket.token;
        return null;
      }
    }
    return null;
  }

  static Future<void> authorize(String tokenToAuthorize) async {
    final ticket = _authorizationTickets[tokenToAuthorize];
    if (ticket == null) return;
    if (!await _kit.exists()) {
      await _kit.create(type: SKitType.authveld);
    }
    final certificate =
        await SCertificateCreator(ticket.applicationName, ticket.policies)
            .create();
    await _kit.addRoot(certificate);
    await _kit.save(encryptKey: "AuthVeld");
    ticket.token = certificate.hash;
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

  static String generateTicketID([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  static String getDetailsPage(String ticketId) {
    final XmlBuilder builder = XmlBuilder();
    final ticket = _authorizationTickets[ticketId];
    builder.doctype('html');
    builder.element('html', nest: () {
      builder.attribute('lang', 'en');
      builder.xml("""<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #181a1b;
            font-family: sans-serif;
            display: flex;
            align-items: left;
            justify-content: left;
            text-align: left;
            color: white;
        }

        .parent-container {
            display: flex;
            flex-direction: column;
            width: 100%;
            height: 100%;
        }
    </style>
</head>""");
      builder.element('body', nest: () {
        builder.element('div', attributes: {"class": "parent-container"},
            nest: () {
          builder.element('h1', nest: () {
            builder.text('Permissions Requested:');
          });
          for (final policy in ticket!.policies) {
            policy.details(builder);
          }
        });
      });
    });
    return builder.buildDocument().toXmlString(pretty: true, newLine: "\n");
  }

  static Future<SCertificate?> loadCertificate(String hash) async {
    if (await _kit.exists()) {
      return await _kit.getRoot<SCertificate>(
        filterRoots: (root) => root.hash == hash,
        addToCache: true,
      );
    }
    return null;
  }

  static Future<bool> hasCertificate(String hash) async {
    if (await _kit.exists()) {
      return await _kit.hasRoot(hash);
    }
    return false;
  }
}

class AuthVeldException implements Exception {
  final String message;
  AuthVeldException(this.message);

  @override
  String toString() => message;
}

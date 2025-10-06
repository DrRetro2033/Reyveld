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

  /// A list of all the tickets that are currently being authorized.
  static final Set<AuthorizeTicket> _authorizationTickets = {};

  static final StreamController<AuthorizeEvent> _authorizationController =
      StreamController.broadcast();

  static Future<String?> getAuthorization(
      String name, String reasoning, List<SPolicy> permissions) async {
    final ticket =
        AuthorizeTicket(generateTicketID(), name, reasoning, permissions);
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

  /// Authorizes a ticket by creating a certificate and adding it to the kit file.
  ///
  /// If the kit file does not exist, it will be created.
  ///
  /// If the certificate already exists inside the kit file, it will be reauthorized.
  static Future<void> authorize(String tokenToAuthorize) async {
    final ticket = _authorizationTickets[tokenToAuthorize];
    if (ticket != null) {
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
    } else if (await _kit.exists() &&
        await AuthVeld.hasCertificate(tokenToAuthorize)) {
      await _kit
          .getRoot<SCertificate>(
              filterRoots: (root) => root.hash == tokenToAuthorize)
          .then((value) async => value!.reauthorize());
      await _kit.save(encryptKey: "AuthVeld");
    }
  }

  /// Revokes the authorization of a ticket.
  ///
  /// If the ticket is currently being authorized, removes it from the authorization list.
  ///
  /// If the ticket is not currently being authorized, but the corresponding exists in the AuthVeld kit file,
  /// then it will deauthorize the certificate.
  static Future<void> deauthorize(String tokenToUnauthorize) async {
    final ticket = _authorizationTickets[tokenToUnauthorize];
    if (ticket != null) {
      _authorizationController.add((ticket, false));
      _authorizationTickets.remove(ticket);
    } else if (await _kit.exists() &&
        await AuthVeld.hasCertificate(tokenToUnauthorize)) {
      await _kit
          .getRoot<SCertificate>(
              filterRoots: (root) => root.hash == tokenToUnauthorize)
          .then((value) async => value!.deauthorize());
      await _kit.save(encryptKey: "AuthVeld");
    }
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
    final ticket = _authorizationTickets[ticketId];
    return """
<!DOCTYPE html>
<html>
<head>
    <title>Markdown in HTML</title>
    <meta charset="utf-8"/>
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <style>
        body {
            font-family: "Arial", sans-serif;
            font-size: 16px;
        }
    </style>
</head>
<body>
    <div id="markdown-content">
        <!-- Markdown content will be rendered here -->
    </div>

    <script>
        const markdownText = `
# Requested Permissions
${ticket?.policies.map((p) => p.details()).join('\n\n')}

# Reasoning
${ticket?.reasoning}
`;
        document.getElementById('markdown-content').innerHTML = marked.parse(markdownText);
    </script>
</body>
</html>
""";
  }

  static Future<SCertificate?> loadCertificate(String token) async {
    if (await _kit.exists()) {
      return await _kit.getRoot<SCertificate>(
        filterRoots: (root) => root.hash == token,
        addToCache: true,
      );
    }
    return null;
  }

  static Future<bool> hasCertificate(String token) async {
    if (await _kit.exists()) {
      return await _kit.hasRoot(token);
    }
    return false;
  }

  static Future<Iterable<SCertificate>> getCertificates() async {
    if (await _kit.exists()) {
      final certs = await _kit.getRoots<SCertificate>(addToCache: true);
      return certs.whereType<SCertificate>();
    }
    return [];
  }
}

class AuthVeldException implements Exception {
  final String message;
  AuthVeldException(this.message);

  @override
  String toString() => message;
}

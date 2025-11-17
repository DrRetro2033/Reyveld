import 'dart:async';
import 'dart:math';

import 'package:reyveld/reyveld.dart';
import 'package:reyveld/security/authorize_ticket.dart';
import 'package:reyveld/security/contract/contract.dart';
import 'package:reyveld/security/policies/policy.dart';
import 'package:reyveld/skit/skit.dart';
import 'package:open_url/open_url.dart';

part 'authveld.interface.dart';
part 'authveld.website.dart';

typedef AuthorizeEvent = (AuthorizeTicket, bool);

class AuthVeld {
  static const _encryptKey = "AuthVeld";

  static final SKit _kit = SKit("${Reyveld.appDataPath}/authveld.skit");

  /// A list of all the tickets that are currently being authorized.
  static final Set<AuthorizeTicket> _authorizationTickets = {};

  static final StreamController<AuthorizeEvent> _authorizationController =
      StreamController.broadcast();

  /// Requests authorization for an application to use Reyveld.
  ///
  /// [name] is the name of the application.
  /// [permissions] is a list of [SPolicy]s that the application wants to use.
  ///
  /// If the user authorizes the ticket, then the returned [Future] will complete with the token of the ticket.
  /// If the user denies the ticket, then the returned [Future] will complete with null.
  /// If the user closes the authorization dialog without making a decision, then the returned [Future] will not complete at all.
  static Future<String?> newContract(
      String name, List<SPolicy> permissions) async {
    final ticket = AuthorizeTicket(generateTicketID(), name, permissions);
    _authorizationTickets.add(ticket);
    await openUrl(
        "http://127.0.0.1:7274/authveld?ticket=${Uri.encodeQueryComponent(ticket.ticket)}");
    await for (final event in _authorizationController.stream) {
      if (event.$1 == ticket) {
        if (event.$2) {
          if (!await _kit.exists()) {
            await _kit.create(type: SKitType.authveld);
          }
          final certificate =
              SContractCreator(ticket.applicationName, ticket.policies)
                  .create();
          await _kit.addRoot(certificate);
          await _kit.save(encryptKey: _encryptKey);
          ticket.token = certificate.id;
          return ticket.token;
        }
        return null;
      }
    }
    return null;
  }

  static Future<String?> verifyContract(SContract contract) async =>
      await newContract(contract.appname, contract.policies);

  static Future<void> deleteContract(String token) async {
    if (await AuthVeld.hasContract(token)) {
      await AuthVeld.getContract(token).then((e) => e!.markForDeletion());
      await _kit.save(encryptKey: _encryptKey);
    }
  }

  /// Reauthorizes a contract.
  static Future<void> authorizeContract(String tokenToAuthorize) async {
    if (await _kit.exists() && await AuthVeld.hasContract(tokenToAuthorize)) {
      await _kit
          .getRoot<SContract>(
              filterRoots: (root) => root.id == tokenToAuthorize)
          .then((value) async => value!.reauthorize());
      await _kit.save(encryptKey: _encryptKey);
    }
  }

  /// Revokes the authorization of a contract.
  static Future<void> deauthorizeContract(String tokenToUnauthorize) async {
    if (await _kit.exists() && await AuthVeld.hasContract(tokenToUnauthorize)) {
      await _kit
          .getRoot<SContract>(
              filterRoots: (root) => root.id == tokenToUnauthorize)
          .then((value) async => value!.deauthorize());
      await _kit.save(encryptKey: _encryptKey);
    }
  }

  /// Accepts an authorization ticket.
  static Future<void> acceptTicket(String ticketId) async {
    final ticket = _authorizationTickets[ticketId];
    if (ticket != null) {
      _authorizationController.add((ticket, true));
      _authorizationTickets.remove(ticket);
    }
  }

  /// Rejects an authorization ticket.
  static Future<void> rejectTicket(String ticketId) async {
    final ticket = _authorizationTickets[ticketId];
    if (ticket != null) {
      _authorizationController.add((ticket, false));
      _authorizationTickets.remove(ticket);
    }
  }

  /// Clears all contracts.
  static Future<void> clearContracts() async => await _kit.delete();

  static Future<void> revokeContracts(String appName) async {
    if (await _kit.exists()) {
      final contract = await _kit.getRoot<SContract>(
          filterRoots: (root) => root.appname == appName);
      if (contract != null) {
        contract.markForDeletion();
      }
      await _kit.save(encryptKey: _encryptKey);
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
${ticket?.policies.map((p) => p.details()).join('\n')}
`;
        document.getElementById('markdown-content').innerHTML = marked.parse(markdownText);
    </script>
</body>
</html>
""";
  }

  static Future<SContract?> getContract(String token) async {
    if (await _kit.exists()) {
      return await _kit.getRoot<SContract>(
        filterRoots: (root) => root.id == token,
        addToCache: true,
      );
    }
    return null;
  }

  static Future<bool> hasContract(String token) async {
    if (await _kit.exists()) {
      return await _kit.hasRoot(token);
    }
    return false;
  }

  static Future<bool> requiresUpdate(
      String token, List<SPolicy> policies) async {
    if (await _kit.exists()) {
      final contract = await getContract(token);
      if (contract != null) {
        if (!contract.verify(policies)) {
          return true;
        }
        return false;
      }
    }
    return true;
  }

  static Future<Iterable<SContract>> getContracts() async {
    if (await _kit.exists()) {
      final certs = await _kit.getRoots<SContract>(addToCache: true);
      return certs.whereType<SContract>();
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

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jne_household_app/helper/remote/auth.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';

class AccessCredentials {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiry;

  AccessCredentials({
    required this.accessToken,
    this.refreshToken,
    required this.expiry,
  });

  String toJsonString() {
    return jsonEncode({"accessToken": accessToken, "refreshToken": refreshToken, "expiry": expiry.toString()});
  }
}

class AuthorizationCodeGrantServerFlow {
  final String clientId;
  final String clientSecret;
  final List<String> scopes;
  final Function userPrompt;
  final int listenPort;
  final String? customPostAuthPage;

  AuthorizationCodeGrantServerFlow({
    required this.clientId,
    required this.clientSecret,
    required this.scopes,
    required this.userPrompt,
    this.listenPort = 0,
    this.customPostAuthPage,
  });

  Future<AccessCredentials> run() async {
    final server = await HttpServer.bind('localhost', listenPort);

    try {
      const redirectUri = iCloudRedirectUri;
      final state = _randomState();

      // Prompt user and wait for them to authorize.
      final authUrl = _buildAuthUrl(redirectUri, state);
      await userPrompt(authUrl);

      // Wait for the server to receive the callback.
      final request = await server.first;
      final uri = request.uri;

      try {
        if (request.method != 'GET') {
          throw Exception(
            'Invalid response from server (expected GET request callback, got: ${request.method}).',
          );
        }

        final returnedState = uri.queryParameters['state'];
        if (state != returnedState) {
          throw Exception('Invalid response from server (state did not match).');
        }

        final error = uri.queryParameters['error'];
        if (error != null) {
          throw Exception(
            'Error occurred while obtaining access credentials: $error',
          );
        }

        final code = uri.queryParameters['code'];
        if (code == null || code.isEmpty) {
          throw Exception('Invalid response from server (no auth code transmitted).');
        }

        final credentials = await _exchangeCodeForToken(
          code,
          redirectUri,
        );

        request.response
          ..statusCode = 200
          ..headers.set('content-type', 'text/html; charset=UTF-8')
          ..write(
            customPostAuthPage ??
                '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Authorization successful.</title>
  </head>
  <body>
    <h2 style="text-align: center">Application has successfully obtained access credentials</h2>
    <p style="text-align: center">This window can be closed now.</p>
  </body>
</html>''',
          );
        await request.response.close();

        return credentials;
      } catch (e) {
        request.response.statusCode = 500;
        await request.response.close().catchError((_) {});
        rethrow;
      }
    } finally {
      await server.close();
    }
  }

  Future<AccessCredentials> refreshAccessToken(String refreshToken) async {
    const tokenUrl = "https://appleid.apple.com/auth/token";

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "client_id": clientId,
        "client_secret": clientSecret,
        "refresh_token": refreshToken,
        "grant_type": "refresh_token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      final newRefreshToken = data['refresh_token'] ?? refreshToken;
      final expiresIn = data['expires_in'];
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));

      return AccessCredentials(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        expiry: expiry,
      );
    } else {
      throw Exception('Failed to refresh access token: ${response.body}');
    }
  }

  String _buildAuthUrl(String redirectUri, String state) {
    final scopesEncoded = Uri.encodeComponent(scopes.join(' '));
    return "https://appleid.apple.com/auth/authorize"
        "?client_id=$clientId"
        "&response_type=code"
        "&redirect_uri=${Uri.encodeComponent(redirectUri)}"
        "&scope=$scopesEncoded"
        "&state=$state";
  }

  Future<AccessCredentials> _exchangeCodeForToken(String code, String redirectUri) async {
    const tokenUrl = "https://appleid.apple.com/auth/token";
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "client_id": clientId,
        "client_secret": clientSecret,
        "code": code,
        "redirect_uri": redirectUri,
        "grant_type": "authorization_code",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final expiresIn = data['expires_in'];
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));

      return AccessCredentials(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiry: expiry,
      );
    } else {
      throw Exception('Failed to exchange code for token: ${response.body}');
    }
  }

  String _randomState() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }
}


class TokenManager {
  AccessCredentials? _credentials;
  AuthorizationCodeGrantServerFlow flow;
  final _logger = Logger();

  TokenManager(this._credentials, this.flow);

  Future<String> getAccessToken() async {
    if (_credentials == null) {
      throw Exception("No access credentials available.");
    }

    final now = DateTime.now();
    if (_credentials!.expiry.isBefore(now)) {
      _credentials = await flow.refreshAccessToken(_credentials!.refreshToken!);
      await saveKey(_credentials!.toJsonString(), "iCloudAccessTokenJson");

      _logger.debug("Access Token refreshed", tag: "iCloud");
    } else if (kDebugMode) {
      _logger.debug("Access Token still valid until ${_credentials!.expiry.toString()}", tag: "iCloud");
    }
    return _credentials!.accessToken;
  }
}

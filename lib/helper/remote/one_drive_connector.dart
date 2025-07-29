import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jne_household_app/helper/remote/auth.dart';
import 'package:jne_household_app/helper/remote/one_drive_auth_code_server.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OneDriveConnector {
  static OneDriveConnector? _instance;
  static String? _accessToken;

  OneDriveConnector._internal();

  factory OneDriveConnector() {
    _instance ??= OneDriveConnector._internal();
    return _instance!;
  }

  Future<void> init() async {
    final flow = AuthorizationCodeGrantServerFlow(
      clientId: getOneDriveClientId(),
      clientSecret: "",
      scopes: ["Files.ReadWrite.All", "User.Read", "offline_access"],
      userPrompt: _promptUserForConsent
    );

    try {
      final savedToken = jsonDecode(await loadKey("oneDriveAccessTokenJson"));
      final tokenManager = TokenManager(
        AccessCredentials(
          accessToken: savedToken['accessToken'], 
          expiry: DateTime.parse(savedToken['expiry']), 
          refreshToken: savedToken['refreshToken']
        ), 
        flow
      );

      if (savedToken != "") {
        _accessToken = await tokenManager.getAccessToken();

        if (kDebugMode) debugPrint("Access token loaded.");
      } else {
        final credentials = await flow.run();
        if (kDebugMode) {
          debugPrint(credentials.toJsonString());
        }
        _accessToken = credentials.accessToken;
        await saveKey(credentials.toJsonString(), "oneDriveAccessTokenJson");
      }
    } catch (e) {
      Logger().info("Failed to load token: $e", tag: "oneDrive");

      final credentials = await flow.run();
      if (kDebugMode) {
        debugPrint(credentials.toString());
      }
      _accessToken = credentials.accessToken;
      await saveKey(credentials.toJsonString(), "oneDriveAccessTokenJson");
    }
  }

  Future<void> _promptUserForConsent(authUrl) async {
    if (await canLaunchUrlString(authUrl)) {
      await launchUrlString(authUrl);
    } else {
      throw Exception("Could not launch $authUrl");
    }
  }

  Future<List<dynamic>> readDirectoryAndFiles(String folderId) async {
    final uri = folderId.isEmpty
        ? Uri.parse("https://graph.microsoft.com/v1.0/me/drive/root/children")
        : Uri.parse("https://graph.microsoft.com/v1.0/me/drive/items/$folderId/children");
    final response = await _authenticatedGet(uri);
    return response["value"] as List<dynamic>;
  }

  Future<List<dynamic>> readDirectory(String folderId) async {
    final allItems = await readDirectoryAndFiles(folderId);
    return allItems.where((item) => item.containsKey("folder")).toList();
  }

  Future<void> downloadFile(String fileName, File localFile, String folderUrl) async {
    String itemId = await loadKey("oneDriveItemId");
    if (itemId == "") {
      await getItemId(folderUrl, fileName);
      itemId = await loadKey("oneDriveItemId");
    }

    final downloadUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$itemId/content";
    final response = await http.get(Uri.parse(downloadUrl), headers: await _authHeaders(false));

    await localFile.writeAsBytes(response.bodyBytes);
  }

  Future<void> uploadFile(String folderId, File localFile, String fileName, {bool overwrite = true}) async {
    folderId = folderId.replaceFirst("onedrive://", "");
    fileName = fileName.replaceAll("/", "");
    
    final itemId = await loadKey("oneDriveItemId");
    final uri = (itemId != "") ?
      Uri.parse("https://graph.microsoft.com/v1.0/me/drive/items/$itemId/content")
      :
      Uri.parse("https://graph.microsoft.com/v1.0/me/drive/items/$folderId:/$fileName:/content");

    http.Response response = await _authenticatedPut(uri, localFile);
    if (itemId == "") {
      String id = jsonDecode(response.body)['id'];
      await saveKey(id, "oneDriveItemId");
    }
  }

  Future<void> getItemId(String folderId, String fileName) async {
    folderId = folderId.replaceFirst("onedrive://", "");
    fileName = fileName.replaceFirst("/", "");

    final items = await readDirectoryAndFiles(folderId);
    for (dynamic item in items) {
      if (item["name"] == fileName) {
        await saveKey(item["id"], "oneDriveItemId");
      }
    }
  } 

  Future<bool> checkExistence(String folderId, String fileName) async {
    folderId = folderId.replaceFirst("onedrive://", "");
    fileName = fileName.replaceFirst("/", "");
    final items = await readDirectoryAndFiles(folderId);
    bool result = items.any((item) => item["name"] == fileName);
    return result;
  }

  Future<Map<String, dynamic>> _authenticatedGet(Uri uri) async {
    final response = await http.get(uri, headers: await _authHeaders(false));
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch data: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  Future<http.Response> _authenticatedPut(Uri uri, File data) async {
    final fileBytes = await data.readAsBytes();
    final response = await http.put(uri, headers: await _authHeaders(true), body: fileBytes);
    if (response.statusCode >= 400) {
      throw Exception("Failed to upload file: ${response.body}");
    }
    return response;
  }

  Future<Map<String, String>> _authHeaders(put) async {
    await init();
    if (_accessToken == null) {
      throw Exception("Access token not available.");
    }
    if (put) {
      return {"Authorization": "Bearer $_accessToken", "Content-Type": "application/octet-stream"};
    } else {
      return {"Authorization": "Bearer $_accessToken"};
    }
  }

}

String getOneDriveClientId() => oneDriveClientId;
String getOneDriveClientSecret() => oneDriveClientSecret;
String getOneDriveRedirectUri() => oneDriveRedirectUri;
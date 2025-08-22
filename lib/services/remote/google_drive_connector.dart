import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:jne_household_app/helper/post_auth_page.dart';
import 'package:jne_household_app/services/remote/auth.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:url_launcher/url_launcher_string.dart';

final scopes = [drive.DriveApi.driveScope];

class GoogleDriveConnector {
  static drive.DriveApi? _driveApi;
  static final GoogleDriveConnector _instance = GoogleDriveConnector._internal();
  final _logger = Logger();

  factory GoogleDriveConnector() => _instance;

  GoogleDriveConnector._internal();

  Future<drive.DriveApi> get driveApi async {
    _driveApi ??= await init();
    return _driveApi!;
  }

  Future<drive.DriveApi> init() async {
    final clientId = ClientId(
      getClientId(),
      getClientSecret(),
    );

    try {
      // Überprüfe gespeicherte Tokens
      final accessTokenJson = await loadKey("googleAccessToken");
      final refreshToken = await loadKey("googleRefreshToken");

      if (accessTokenJson != "" && refreshToken != "") {
        final accessTokenMap = jsonDecode(accessTokenJson);
        final accessToken = AccessToken(
          accessTokenMap['type'],
          accessTokenMap['data'],
          DateTime.parse(accessTokenMap['expiry']),
        );

        // Wenn Access Token gültig ist
        if (DateTime.now().isBefore(accessToken.expiry)) {
          _logger.debug("Access Token is still valid.", tag: "googleDrive");

          final authClient = authenticatedClient(accessToken, refreshToken, clientId);
          return drive.DriveApi(authClient);
        } else {
          _logger.debug("Access Token expired, refreshing...", tag: "googleDrive");
          
          // Access Token erneuern
          final refreshedClient = await refreshAuthToken(clientId, accessToken, refreshToken);
          return drive.DriveApi(refreshedClient);
        }
      }
    } catch (e) {
      _logger.error("Failed to use saved credentials: $e", tag: "googleDrive");
    }

    final authClient = await clientViaUserConsent(clientId, scopes, _promptUserForConsent, customPostAuthPage: customPostAuthPage);
    await _saveCredentials(authClient.credentials);
    return drive.DriveApi(authClient);
  }

  Future<void> _saveCredentials(AccessCredentials creds) async {
    Map<String, dynamic> accessToken = {
      "type": creds.accessToken.type,
      "data": creds.accessToken.data,
      "expiry": creds.accessToken.expiry.toString()
    };

    await saveKey(json.encode(accessToken), "googleAccessToken");
    await saveKey(creds.refreshToken!, "googleRefreshToken");
  }

  // Hilfsfunktion: Authentifizierten Client erstellen
  AuthClient authenticatedClient(
    AccessToken accessToken,
    String refreshToken,
    ClientId clientId
  ) {
    final credentials = AccessCredentials(accessToken, refreshToken, scopes);
    final httpClient = http.Client();
    return autoRefreshingClient(getClient(), credentials, httpClient);
  }

  // Hilfsfunktion: Access Token mit Refresh Token erneuern
  Future<AuthClient> refreshAuthToken(
    ClientId clientId,
    AccessToken expiredToken,
    String refreshToken
  ) async {
    final httpClient = http.Client();

    final refreshedCredentials = await refreshCredentials(clientId, AccessCredentials(
      expiredToken,
      refreshToken,
      scopes,
    ),
    httpClient);

    await _saveCredentials(refreshedCredentials);
    return authenticatedClient(refreshedCredentials.accessToken, refreshedCredentials.refreshToken!, clientId);
  }


  void _promptUserForConsent(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw Exception("Could not launch $url");
    }
  }

  Future<List<drive.File>> readDirectoryAndFiles(String folderId) async {
    final client = await driveApi;
    final fileList = await client.files.list(q: "'$folderId' in parents", $fields: 'files(id, name, mimeType)');
    return fileList.files ?? [];
  }

  Future<List<drive.File>> readDirectory(String folderId) async {
    final client = await driveApi;

    drive.FileList fileList;

    if (folderId == "") {
      fileList = await client.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder'",
        $fields: 'files(id, name, ownedByMe, owners)',
        orderBy: "name",
        includeItemsFromAllDrives: false
      );
    } else {
      fileList = await client.files.list(
        q: "'$folderId' in parents and mimeType = 'application/vnd.google-apps.folder'",
        $fields: 'files(id, name, ownedByMe, owners)',
        orderBy: "name",
        includeItemsFromAllDrives: false
      );
    }
    final files = fileList.files ?? [];

    final ownFolders = files.where((file) => file.ownedByMe == true).toList();
    final sharedFolders = files.where((file) => file.ownedByMe == false).toList();

    ownFolders.sort((a, b) => a.name!.compareTo(b.name!));
    sharedFolders.sort((a, b) => a.name!.compareTo(b.name!));

    return [...ownFolders, ...sharedFolders];
  }

  Future<void> downloadFile(String fileName, File localFile) async {
    String fileId = await loadKey("googleDriveItemId");
    final client = await driveApi;
    if (fileId == "") {
      await getItemId(fileName, client);
      fileId = await loadKey("googleDriveItemId");
    }
    
    // Lade die Datei herunter
    final media = await client.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia);
    final sink = localFile.openWrite(encoding: Encoding.getByName("utf-8")!);

    try {
      if (media is drive.Media) {
        await for (final data in media.stream) {
          sink.add(data);
        }
      }
    } catch (e){
      logger.error("Download of pbdb file failed: $e", tag: "googleDrive");
    } finally {
      await sink.close();
    }
  }

  Future<void> getItemId(String fileName, dynamic client) async {
    fileName = fileName.replaceFirst("/", "");

    // Suche nach der Datei basierend auf dem Namen
    final searchResult = await client.files.list(
      q: "name = '$fileName'",
      $fields: "files(id, name)",
    );

    final files = searchResult.files ?? [];
    if (files.isEmpty) {
      throw Exception("File with name '$fileName' not found.");
    }
    await saveKey(files.first.id!, "googleDriveItemId");
  }

  Future<void> uploadFile(String folderId, File localFile, String fileName, {bool overwrite = true}) async {
    folderId = folderId.replaceFirst("gdrive://", "");
    fileName = fileName.replaceAll("/", "");
    final client = await driveApi;

    String fileId = await loadKey("googleDriveItemId");

    final media = drive.Media(localFile.openRead(), localFile.lengthSync());

    if (overwrite && fileId != "") {
      final fileToUpload = drive.File()
        ..name = fileName;

      if ((await client.files.update(fileToUpload, fileId, uploadMedia: media, keepRevisionForever: false)).id == "") {
        logger.error("Update of pbdb file failed", tag: "googleDrive");
      }
      _logger.debug("Updated shared database file", tag: "googleDrive");
    } else {
      final fileToUpload = drive.File()
        ..name = fileName
        ..parents = [folderId];

      fileId = (await client.files.create(fileToUpload, uploadMedia: media)).id ?? "";
      if(fileId == ""){
        logger.error("Upload of pbdb file failed", tag: "googleDrive");
      } else {
        await saveKey(fileId, "googleDriveItemId");
      }
      _logger.debug("Created shared database file", tag: "googleDrive");
    }
  }

  Future<bool> checkExistence(String folderId, String fileName) async {
    folderId = folderId.replaceFirst("gdrive://", "");
    final client = await driveApi;
    final fileList = await client.files.list(
      q: "'$folderId' in parents and name = '${fileName.replaceAll("/", "")}'",
      $fields: 'files(id)',
    );
    return fileList.files?.isNotEmpty ?? false;
  }
}

ClientId getClient() => ClientId(getClientId(), getClientSecret());

String getClientId() => googleDriveClientId;

String getClientSecret() => googleDriveClientKey;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jne_household_app/helper/remote/google_drive_connector.dart';
import 'package:jne_household_app/helper/remote/one_drive_connector.dart';
import 'package:jne_household_app/helper/remote/smb_server.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/shared_database/encryption_handler.dart';

const String sharedDbName = "/pureBudgetRemoteDatabase.pbdb";

Future<void> uploadFile(String remotePath, File localFile) async {
  try {
    if (! await EncryptionHelper.encryptFile(localFile)){
      throw Exception("Could not encrypt file");
    }

    final encryptedFile = File('${localFile.path}.encrypted');

    // Tatsächlichen Upload an remotePath durchführen
    if (remotePath.startsWith('gdrive://')) {
      await GoogleDriveConnector().uploadFile(remotePath, encryptedFile, sharedDbName);
    } else if (remotePath.startsWith('onedrive://')) {
      await OneDriveConnector().uploadFile(remotePath, encryptedFile, sharedDbName);
    } else if (remotePath.startsWith('smb://')) {
      await SMBServer().uploadFile(remotePath, encryptedFile, sharedDbName);
    } else {
      await uploadToLocal(remotePath, encryptedFile);
    }

    // Temporäre verschlüsselte Datei löschen
    await encryptedFile.delete();
  } catch (e) {
    Logger().error("Error uploading file: $e", tag: "network");
    rethrow;
  }
}


Future<bool> downloadFile(String remotePath, File localFile) async {
  try {
    // Lade die verschlüsselte Datei
    File encryptedFile;
    if (kDebugMode) {
      encryptedFile = File('${localFile.path}_debug.encrypted');
    } else {
      encryptedFile = File('${localFile.path}.encrypted');
    }

    if (!await encryptedFile.exists()) {
      await encryptedFile.create(recursive: true);
    }

    debugPrint(remotePath);

    if (remotePath.startsWith("gdrive://")) {
      await GoogleDriveConnector().downloadFile(sharedDbName, encryptedFile);
    } else if (remotePath.startsWith("onedrive://")) {
      await OneDriveConnector().downloadFile(sharedDbName, encryptedFile, remotePath);
    } else if (remotePath.startsWith("smb://")) {
      await SMBServer().downloadFile(remotePath, encryptedFile, sharedDbName);
    } else {
      await _downloadFromLocal(remotePath, encryptedFile);
    }

    // read encoded file
    final encryptedBytes = await encryptedFile.readAsBytes();

    final keyBase64 = await EncryptionHelper.loadKey();
    final key = EncryptionHelper.getKeyFromBase64(keyBase64);


    // decode file content
    final decryptedBytes = await EncryptionHelper.decryptFile(encryptedBytes, key);

    if (!await localFile.exists()) {
      await localFile.create(recursive: true);
    }
    final sink = localFile.openWrite();
    try {
      sink.add(decryptedBytes); // write bytes to file
    } finally {
      await sink.close(); // ensure closing file
    }

    // Delete temporary encrypted file
    await encryptedFile.delete();
    return true;
  } catch (e) {
    Logger().error("Error downloading file: $e", tag: "network");
    return false;
  }
}

Future<void> uploadToLocal(String remotePath, File encryptedFile) async {
  final destination = File(remotePath + sharedDbName);

  await encryptedFile.copy(destination.path);
}


Future<void> _downloadFromLocal(String remotePath, File encryptedFile) async {
  final nasFile = File(remotePath + sharedDbName);
  if (await nasFile.exists()) {
    await encryptedFile.writeAsString(await nasFile.readAsString());
  } else {
    throw Exception("NAS-Datei nicht gefunden: $remotePath");
  }
}


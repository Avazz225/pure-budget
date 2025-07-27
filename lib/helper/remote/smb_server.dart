import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jne_household_app/helper/remote/auth.dart';
import 'package:smb_connect/smb_connect.dart';

class SMBServer {
  static SmbConnect? _smbClient;
  static final SMBServer _instance = SMBServer._internal();

  factory SMBServer() => _instance;

  SMBServer._internal();

  Future<SmbConnect> get smbClient async {
    _smbClient ??= await init();
    try {
      List<SmbFile> files = await _smbClient!.listShares();
      if (files.isEmpty) {
        throw Exception("No shared found.");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Reestablishing db connection: $e");
      }
      _smbClient = await init();
    }
    return _smbClient!;
  }

  Future<SmbConnect> init({String? host, String? username, String? password, String? domain}) async {
    final hostStr = host ?? await loadKey("smbHost");
    final usernameStr = username ?? await loadKey("smbUname");
    final passwordStr = password ?? await loadKey("smbPwd");
    final domainStr = domain ?? await loadKey("smbDom");

    if (host != null && host != await loadKey("smbHost")) {
      await saveKey(host, "smbHost");
    }
    if (username != null && username != await loadKey("smbUname")) {
      await saveKey(username, "smbUname");
    }
    if (password != null && password != await loadKey("smbPwd")) {
      await saveKey(password, "smbPwd");
    }
    if (domain != null && domain != await loadKey("smbDom")) {
      await saveKey(domain, "smbDom");
    }

    try {
      return await SmbConnect.connectAuth(
        host: hostStr,
        username: usernameStr,
        password: passwordStr,
        domain: domainStr,
      );
    } catch (e) {
      throw Exception("Failed to connect to SMB server: $e");
    }
  }

  Future<List<SmbFile>> readDirectoryAndFiles(String path) async {
    if (path.isEmpty) {
      path = "/";
    }

    final client = await smbClient;
    SmbFile folderSmb = await client.file(path);
    List<SmbFile> filesAndFolders = await client.listFiles(folderSmb);

    List<SmbFile> folders = filesAndFolders.where((item) => item.isDirectory()).toList();
    List<SmbFile> files = filesAndFolders.where((item) => !item.isDirectory()).toList();

    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return [...folders, ...files];
  }

  Future<List<SmbFile>> readDirectory(String path) async {
    if (path.isEmpty) {
      path = "/";
    }

    final client = await smbClient;
    SmbFile folderSmb = await client.file(path);
    List<SmbFile> filesAndFolders = await client.listFiles(folderSmb);

    List<SmbFile> folders = filesAndFolders.where((item) => item.isDirectory()).toList();
    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return folders;
  }

  Future<void> downloadFile(String path, File encryptedFile, String sharedDbName) async {
    final client = await smbClient;

    SmbFile file = await client.file("${path.replaceAll("smb://", "")}/$sharedDbName");
    Stream<Uint8List> reader = await client.openRead(file);
    final IOSink sink = encryptedFile.openWrite();
    try {
      await for (final chunk in reader) {
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }

  Future<void> uploadFile(String path, File encryptedFile, String sharedDbName) async {
    final client = await smbClient;
    SmbFile file;
    try {
      file = await client.file("${path.replaceAll("smb://", "")}/$sharedDbName");
    } catch (e) {
      file = await client.createFile("${path.replaceAll("smb://", "")}/$sharedDbName");
    }

    
    IOSink writer = await client.openWrite(file);

    writer.add(encryptedFile.readAsBytesSync());
    await writer.flush();
    await writer.close();
  }

  Future<bool> checkExistence(String path, String sharedDbName) async {
    final client = await smbClient;
    SmbFile file = await client.file("${path.replaceAll("smb://", "")}/$sharedDbName");
    return file.isExists;
  }
}
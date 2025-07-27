import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' as mode;
import 'package:jne_household_app/helper/remote/auth.dart' as storage;


class EncryptionHelper {
  static const _keyIdentifier = "encryption_key";

  // Generate a new encryption key and save it
  static Future<void> generateKey() async {
    final key = Key.fromSecureRandom(32); // 256-bit key
    final keyBase64 = base64UrlEncode(key.bytes);
    await saveKey(keyBase64);
  }

  static Future<void> saveKey(String value) async {
    await storage.saveKey(value, _keyIdentifier);
  }

  static Future<String> loadKey() async {
    return await storage.loadKey(_keyIdentifier);
  }

  // Decode the Base64-encoded key to a Key object
  static Key getKeyFromBase64(String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    return Key(Uint8List.fromList(keyBytes));
  }

  // Decrypt a file's bytes
  static Future<List<int>> decryptFile(Uint8List encryptedBytes, Key key) async {
    if (mode.kDebugMode) {
      mode.debugPrint(key.bytes.toString());
    }
    
    if (encryptedBytes.length < 16) {
      throw Exception("Invalid encrypted data: Missing IV or data segment");
    }

    // Extract the IV (first 16 bytes)
    final ivBytes = encryptedBytes.sublist(0, 16);
    final iv = IV(ivBytes);

    // Extract the encrypted data (bytes after the IV)
    final encryptedDataBytes = encryptedBytes.sublist(16);
    final encryptedData = Encrypted(encryptedDataBytes);

    // Decrypt using AES-CBC
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    try {
      final decryptedBytes = encrypter.decryptBytes(encryptedData, iv: iv);

      return decryptedBytes;
    } catch (e) {
      mode.debugPrint("Decryption error: $e");
      throw Exception("Decryption failed: $e");
    }
  }
}

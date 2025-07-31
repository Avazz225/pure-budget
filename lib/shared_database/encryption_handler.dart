import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:jne_household_app/helper/remote/auth.dart' as storage;
import 'package:jne_household_app/logger.dart';


class EncryptionHelper {
  static const _keyIdentifier = "encryption_key";
  static final _logger = Logger();

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
    _logger.debug(key.bytes.toString(), tag: "decrypt");
    
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
      _logger.error("Decryption error: $e", tag: "decrypt");
      throw Exception("Decryption failed: $e");
    }
  }

  static Future<bool> encryptFile(File localFile) async {
    try {
      final keyBase64 = await loadKey();
      final key = getKeyFromBase64(keyBase64);

      // Initialisiere Encrypter
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final iv = IV.fromSecureRandom(16); // Initialisierungsvektor generieren

      // Datei lesen und verschlüsseln
      final fileBytes = await localFile.readAsBytes();
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Temporäre verschlüsselte Datei erstellen
      final encryptedFile = File('${localFile.path}.encrypted');
      await encryptedFile.writeAsBytes([...iv.bytes, ...encrypted.bytes]);
      return true;
    } catch (e) {
      _logger.error("Encryption error: $e", tag: "encrypt");
      return false;
    }
  }
}

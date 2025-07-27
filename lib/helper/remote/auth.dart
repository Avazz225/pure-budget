import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const String keyPrefix = (kDebugMode) ? "debug_" : "";

Future<void> saveKey(String key, String keyIdentifier) async {
  await _storage.write(key: "$keyPrefix$keyIdentifier", value: key);

  if (kDebugMode) {
    print("Saved key '$key' to '$keyPrefix$keyIdentifier'");
  }
}

// Load the key from a file
Future<String> loadKey(String keyIdentifier) async {
  if (kDebugMode) {
    print("Loading key from'$keyPrefix$keyIdentifier'");
  }

  final key = await _storage.read(key: "$keyPrefix$keyIdentifier");
  if (key == null) {
    return "";
  }
  return key;
}

Future<void> deleteKey(String keyIdentifier) async {
  if (kDebugMode) {
    print("Deleting key '$keyPrefix$keyIdentifier'");
  }

  await _storage.delete(key: "$keyPrefix$keyIdentifier");
}

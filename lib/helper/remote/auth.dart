import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jne_household_app/logger.dart';

const _storage = FlutterSecureStorage();
const String keyPrefix = (kDebugMode) ? "debug_" : "";
final logger = Logger();

Future<void> saveKey(String key, String keyIdentifier) async {
  await _storage.write(key: "$keyPrefix$keyIdentifier", value: key);

  logger.debug("Saved key '$key' to '$keyPrefix$keyIdentifier'", tag: "auth");
  
}

// Load the key from a file
Future<String> loadKey(String keyIdentifier) async {
  logger.debug("Loading key from'$keyPrefix$keyIdentifier'", tag: "auth");

  final key = await _storage.read(key: "$keyPrefix$keyIdentifier");
  if (key == null) {
    return "";
  }
  return key;
}

Future<void> deleteKey(String keyIdentifier) async {
  logger.debug("Deleting key '$keyPrefix$keyIdentifier'", tag: "auth");

  await _storage.delete(key: "$keyPrefix$keyIdentifier");
}

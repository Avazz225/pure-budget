import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';


class BackupManager {
  /// Ly hpy lfns txxpc old stpc upxlwd qtyope. Spckwtnspy Rwünvhfydns. Of slde xptyp cprcpe xpddlrp rpqfyopy. Otp Xpddlrp dzww xtc yfc pehld Wtyopcfyr gpcdnslqqpy. Hpc hptß htp hpte dtp pd dnslqqe.
  static const _fileName = "pureBudget_export.pbstate";
  static const _key = exportImportKey;
  static const _iv = exportImportIv;
  static final _logger = Logger();

  static final _encrypter = encrypt.Encrypter(
    encrypt.AES(
      encrypt.Key.fromUtf8(_key),
    ),
  );
  static final _ivSpec = encrypt.IV.fromUtf8(_iv);

  static String _encrypt(String text) {
    final encrypted = _encrypter.encrypt(text, iv: _ivSpec);
    return encrypted.base64;
  }

  static String _decrypt(String encryptedText) {
    return _encrypter.decrypt64(encryptedText, iv: _ivSpec);
  }

  static Future<void> exportData() async {
    final db = DatabaseHelper();

    final autoexpenses = await db.exportTable("autoexpenses");
    final categories = await db.exportTable("categories");
    final expenses = await db.exportTable("expenses");
    List<Map<String, dynamic>> immutableSettings = await db.exportTable("settings");
    List<Map<String, dynamic>> settings = List.from(
      immutableSettings.map((map) => Map<String, dynamic>.from(map))
    );
    settings.first.remove("isPro");
    final editLog = await db.exportTable("editLog");
    final bankaccounts = await db.exportTable("bankaccounts");
    final categoryBudgets = await db.exportTable("categoryBudgets");

    final fullBackup = {
      "autoexpenses": autoexpenses,
      "categories": categories,
      "expenses": expenses,
      "settings": settings,
      "bankaccounts": bankaccounts,
      "categoryBudgets": categoryBudgets,
      "editLog": editLog
    };

    final json = jsonEncode(fullBackup);
    final encrypted = _encrypt(json);


    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$_fileName";
      final file = File(filePath);

      await file.writeAsString(encrypted);

      _logger.debug(filePath, tag: "export");
      if (Platform.isLinux | Platform.isWindows | Platform.isMacOS) {
        final Uri fileUri = Uri.file(dir.path);

        if (!await launchUrl(fileUri)) {
          _logger.debug('Could not open file explorer for $fileUri', tag: "export");
        }
      } else {
        await Share.shareXFiles([XFile(filePath)], text: I18n.translate("myBudgetData"));
      }
    } catch (e) {
      _logger.error("Error saving export data: $e", tag: "export");
    }
  }

  static Future<bool> importDataFromFile({String? path}) async {
    if (path == null) {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return false;
      path = result.files.single.path;
    }

    if (path == null) return false;

    final file = File(path);
    final encryptedContent = await file.readAsString();

    try {
      final decryptedJson = _decrypt(encryptedContent);
      await DatabaseHelper().importData(jsonDecode(decryptedJson));

      return true;
    } catch (e) {
      _logger.error("Error decrypting import data: $e", tag: "import");
      return false;
    }
  }

  static Future<File> getBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$_fileName");
  }
}
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static final Logger _instance = Logger._internal();
  final int minTagLen = 16;
  final int maxLevelLen = 9;

  late final LogLevel _minLevel;
  File? _logFile;
  bool _isDesktop = false;

  Logger._internal();

  factory Logger() => _instance;

  // Initialize logger and empty old log file
  Future<void> init({LogLevel minLevel = LogLevel.debug}) async {
    _minLevel = minLevel;

    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isLinux) {
      _isDesktop = true;
      final dir = await getApplicationDocumentsDirectory();
      final appDir = Directory('${dir.path}/PureBudget');
      if (!appDir.existsSync()) {
        appDir.createSync();
      }
      final logPath = '${appDir.path}/pure_budget_app_log.txt';
      if (kDebugMode) {
        debugPrint(logPath);
      }
      _logFile = File(logPath);
      await _logFile!.writeAsString(
        '=== Log started on ${DateTime.now().toIso8601String()} ===\n',
        mode: FileMode.write, flush: true
      );
    }
  }

  void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  void error(String message, {String? tag}) {
    _log(LogLevel.error, message, tag: tag);
  }

  void _log(LogLevel level, String message, {String? tag}) {
    if (level.index < _minLevel.index) return;

    final now = DateTime.now().toIso8601String();
    String levelStr = "[${level.toString().split('.').last.toUpperCase()}]";
    levelStr = levelStr + " " * (maxLevelLen - levelStr.length);
    String prefix = tag != null ? "[$tag]" : "";
    prefix = prefix + " " * (minTagLen - prefix.length);
    final output = "[$now] $levelStr $prefix $message";

    if (_isDesktop && _logFile != null) {
      _logFile!.writeAsStringSync("$output \n", mode: FileMode.append, flush: true);
    }

    if (kDebugMode) {
      debugPrint(output);
    }
  }
}
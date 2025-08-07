import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:path/path.dart' as p;
import 'package:screenshot/screenshot.dart';

class ScreenshotManager {
  static final ScreenshotManager _instance = ScreenshotManager._internal();
  factory ScreenshotManager() => _instance;

  ScreenshotManager._internal();

  final ScreenshotController controller = ScreenshotController();
  bool _isListening = false;

  String? _customScreenshotName;
  bool _autoCaptureNext = false;
  String platform = (Platform.isWindows) ? "windows" : (Platform.isMacOS) ? "macos" : "linux";

  void prepareNextAutoScreenshot(String filename) {
    _customScreenshotName = filename;
    _autoCaptureNext = true;
  }

  void enableHotkeyListener({bool debugOnly = true}) {
    if (_isListening) return;

    RawKeyboard.instance.addListener(_handleKeyPress);
    _isListening = true;
  }

  void disableHotkeyListener() {
    if (!_isListening) return;
    RawKeyboard.instance.removeListener(_handleKeyPress);
    _isListening = false;
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyS &&
        event is KeyDownEvent) {
      takeScreenshot();
    }
  }

  Future<void> takeScreenshot({String? name}) async {
    await Future.delayed(Duration(milliseconds: 1500));
    String language = I18n.getLocaleString();
    final image = await controller.capture();
    if (image == null) return;

    final now = DateTime.now();
    final filename = name ??
        _customScreenshotName ??
        'screenshot_${now.toIso8601String().replaceAll(':', '-')}';
    final path = p.join(
      Directory.current.path,
      'app_store_images',
      platform,
      language,
      '$filename.png',
    );

    final file = File(path);
    await file.writeAsBytes(image);

    Logger().debug("Taken screenshot to ${file.path}", tag: "screenshot");

    _customScreenshotName = null;
    _autoCaptureNext = false;
  }

  Widget wrapWithScreenshot({required Widget child}) {
    return Screenshot(
      controller: controller,
      child: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 1500)),
        builder: (context, snapshot) {
          if (_autoCaptureNext && snapshot.connectionState == ConnectionState.done) {
            takeScreenshot(name: _customScreenshotName);
          }
          return child;
        },
      ),
    );
  }
}

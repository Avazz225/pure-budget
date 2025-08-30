import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart'; // Mobile Widgets
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/category_budget.dart';
import 'package:tray_manager/tray_manager.dart'; // Desktop Tray

class QuickActionsService with TrayListener {
  static final QuickActionsService _instance = QuickActionsService._internal();
  late List<CategoryBudget> _categories;
  final _logger = Logger();
  factory QuickActionsService() => _instance;
  QuickActionsService._internal();

  void Function(String action)? _onActionSelected;

  Future<void> init({
    required void Function(String action) onActionSelected,
    required List<CategoryBudget> categories,
    required bool sharedDbRegistered
  }) async {
    _onActionSelected = onActionSelected;
    _categories = categories;

    if (Platform.isAndroid || Platform.isIOS) {
      await _initMobile();
    } else if (Platform.isWindows || Platform.isMacOS) {
      await _initDesktop(sharedDbRegistered);
    } else {
      _logger.debug("QuickActions not supported on this platform.",  tag: "quickActions");
    }
  }

  Future<void> _initMobile() async {
    HomeWidget.setAppGroupId(iosAppGroupId); // for iOS
    HomeWidget.registerInteractivityCallback(_backgroundCallback);

    final launchDetails = await HomeWidget.getWidgetData<String>('action');
    if (launchDetails != null && _onActionSelected != null) {
      _onActionSelected!(launchDetails);
    }

    _logger.debug("Mobile widgets initialized.",  tag: "quickActions");
  }

  // triggered on widget action
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri != null) {
      final action = uri.host; // e.g. myapp://new_expense
      _instance._onActionSelected?.call(action);
    }
  }

  Future<void> _initDesktop(bool sharedDbRegistered) async {
    trayManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows ? 'assets/icons/pb_icon.ico' : 'assets/icons/logo.png',
    );

    await trayManager.setToolTip("Pure Budget");

    final menu = [
      MenuItem.submenu(
        key: 'new_expense', 
        label: I18n.translate('new'),
        submenu: Menu(
          items: _categories.map(
            (c) => MenuItem(
              key: "new?${c.categoryId}",
              label: c.categoryId == -1
                  ? I18n.translate("unassigned")
                  : c.category,
            ),
          )
          .toList()
        )
      ),
      if (sharedDbRegistered)
      MenuItem(key: 'sync', label: I18n.translate("synchronize")),
      MenuItem(key: 'open_budget', label: I18n.translate("open")),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: I18n.translate("exit")),
    ];

    await trayManager.setContextMenu(Menu(items: menu));
    _logger.debug("Desktop tray initialized.",  tag: "quickActions");
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  // triggered on menu selection
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (_onActionSelected != null) {
      _onActionSelected!(menuItem.key ?? '');
    }
  }
}

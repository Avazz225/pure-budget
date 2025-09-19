import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';

class DesignState extends ChangeNotifier {
  bool layoutMainVertical; // home -> budgetSummary
  int categoryMainStyle; // home -> budgetSummary -> categoryList -> listTile style
  int addExpenseStyle; // home -> budgetSummary -> categoryList -> listTile -> "+" style
  int arcStyle; // home -> budgetSummary -> BudgetArcWidget style (arc [0], line [1] or none[2])
  bool arcSegmentsRounded; // home -> budgetSummary -> BudgetArcWidget style (round segments)
  double arcWidth; // home -> budgetSummary -> BudgetArcWidget width
  double arcPercent; // home -> budgetSummary -> BudgetArcWidget portion of full circle (only if arc and not line)
  bool dialogSolidBackground; // all dailogs -> background solid or blurry
  bool appBackgroundSolid; // whole app background solid
  int appBackground; // custom image (0) or predefined background gradients (>=1)
  String customBackgroundPath;
  bool customBackgroundBlur; // only if customBackground is used
  int mainMenuStyle; // button style for main menu
  double blurIntensity; // blur of background image
  Map<String, dynamic> customGradient; // custom gradient for background

  DesignState._({
    required this.layoutMainVertical,
    required this.categoryMainStyle,
    required this.addExpenseStyle, 
    required this.arcStyle, 
    required this.arcPercent,
    required this.arcWidth, 
    required this.arcSegmentsRounded,
    required this.dialogSolidBackground,
    required this.appBackgroundSolid,
    required this.appBackground,
    required this.customBackgroundBlur,
    required this.customBackgroundPath,
    required this.mainMenuStyle,
    required this.blurIntensity,
    required this.customGradient
  });

  factory DesignState({
    required bool layoutMainVertical,
    required int categoryMainStyle,
    required int addExpenseStyle,
    required int arcStyle,
    required double arcPercent,
    required double arcWidth,
    required bool arcSegmentsRounded,
    required bool dialogSolidBackground,
    required bool appBackgroundSolid,
    required int appBackground,
    required bool customBackgroundBlur,
    required String customBackgroundPath,
    required int mainMenuStyle,
    required double blurIntensity,
    required String customGradient
  }) {
    return DesignState._(
      layoutMainVertical: layoutMainVertical,
      categoryMainStyle: categoryMainStyle,
      addExpenseStyle: addExpenseStyle,
      arcPercent: arcPercent,
      arcStyle: arcStyle,
      arcWidth: arcWidth,
      arcSegmentsRounded: arcSegmentsRounded,
      dialogSolidBackground: dialogSolidBackground,
      appBackground: appBackground,
      appBackgroundSolid: appBackgroundSolid,
      customBackgroundBlur: customBackgroundBlur,
      customBackgroundPath: customBackgroundPath,
      mainMenuStyle: mainMenuStyle,
      blurIntensity: blurIntensity,
      customGradient: decodeCustomGradient(customGradient)
    );
  }

  static DesignState initialize({
    required bool layoutMainVertical,
    required int categoryMainStyle,
    required int addExpenseStyle,
    required int arcStyle,
    required double arcPercent,
    required double arcWidth,
    required bool arcSegmentsRounded,
    required bool dialogSolidBackground,
    required bool appBackgroundSolid,
    required int appBackground,
    required bool customBackgroundBlur,
    required String customBackgroundPath,
    required int mainMenuStyle,
    required double blurIntensity,
    required String customGradient
  }) {
    final instance = DesignState(
      layoutMainVertical: layoutMainVertical,
      categoryMainStyle: categoryMainStyle,
      addExpenseStyle: addExpenseStyle,
      arcPercent: arcPercent,
      arcStyle: arcStyle,
      arcWidth: arcWidth,
      arcSegmentsRounded: arcSegmentsRounded,
      dialogSolidBackground: dialogSolidBackground,
      appBackground: appBackground,
      appBackgroundSolid: appBackgroundSolid,
      customBackgroundBlur: customBackgroundBlur,
      customBackgroundPath: customBackgroundPath,
      mainMenuStyle: mainMenuStyle,
      blurIntensity: blurIntensity,
      customGradient: customGradient
    );

    return instance;
  } 

  static Map<String, dynamic> decodeCustomGradient(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);

    if (data["colors"] == null || data["type"] == null) {
      return {
        "colors": [Colors.blue, Colors.purple],
        "type": 0,
      };
    }
    
    final colors = (data["colors"] as List)
        .map((v) => Color(v as int))
        .toList();

    final type = data["type"] as int;

    return {
      "colors": colors,
      "type": type,
    };
  }

  Future<void> updateCustomGradient(Map<String, dynamic> data) async {
    customGradient = data;

    final Map<String, dynamic> processed = {
      "colors": data['colors'].map((c) => c.value).toList(),
      "type": data['type'],
    };
    
    await DatabaseHelper().updateDesign("customGradient", json.encode(processed));
  }

  Future<void> updateMainMenuStyle(int index) async {
    mainMenuStyle = index;
    await DatabaseHelper().updateDesign("mainMenuStyle", index);
    notifyListeners();
  }

  Future<void> updateAddExpenseStyle(int index) async {
    addExpenseStyle = index;
    await DatabaseHelper().updateDesign("addExpenseStyle", index);
    notifyListeners();
  }

  Future<void> updateArcStyle(int index) async {
    arcStyle = index;
    await DatabaseHelper().updateDesign("arcStyle", index);
    notifyListeners();
  }

  Future<void> updateCategoryMainStyle(int index) async {
    categoryMainStyle = index;
    await DatabaseHelper().updateDesign("categoryMainStyle", index);
    notifyListeners();
  }

  Future<void> updateLayoutMainVertical(bool value) async {
    layoutMainVertical = value;
    await DatabaseHelper().updateDesign("layoutMainVertical", (value) ? 1 : 0);
    notifyListeners();
  }

  Future<void> updateArcSegmentsRounded(bool value) async {
    arcSegmentsRounded = value;
    await DatabaseHelper().updateDesign("arcSegmentsRounded", (value) ? 1 : 0);
    notifyListeners();
  }

  Future<void> updateArcWidth(double value) async {
    arcWidth = value;
    await DatabaseHelper().updateDesign("arcWidth", value);
    notifyListeners();
  }

  Future<void> updateArcPercent(double value) async {
    arcPercent = value;
    await DatabaseHelper().updateDesign("arcPercent", value);
    notifyListeners();
  }

  Future<void> updateDialogSolidBackground(bool value) async {
    dialogSolidBackground = value;
    await DatabaseHelper().updateDesign("dialogSolidBackground", (value) ? 1 : 0);
    notifyListeners();
  }

  Future<void> updateAppBackgroundSolid(bool value) async {
    appBackgroundSolid = value;
    await DatabaseHelper().updateDesign("appBackgroundSolid", (value) ? 1 : 0);
    notifyListeners();
  }

  Future<void> updateCustomBackgroundBlur(bool value) async {
    customBackgroundBlur = value;
    await DatabaseHelper().updateDesign("customBackgroundBlur", (value) ? 1 : 0);
    notifyListeners();
  }

  Future<void> updateCustomBackgroundPath(String path) async {
    customBackgroundPath = path;
    await DatabaseHelper().updateDesign("customBackgroundPath", path);
    notifyListeners();
  }

  Future<void> updateAppBackground(int index) async {
    appBackground = index;
    await DatabaseHelper().updateDesign("appBackground", index);
    notifyListeners();
  }

  Future<void> updateBlurIntensity(double blur) async {
    blurIntensity = blur;
    await DatabaseHelper().updateDesign("blurIntensity", blur);
    notifyListeners();
  }
}
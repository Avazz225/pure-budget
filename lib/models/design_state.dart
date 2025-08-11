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

  DesignState._({
    required this.layoutMainVertical, //Done
    required this.categoryMainStyle, //Done
    required this.addExpenseStyle,  //Done
    required this.arcStyle,  //Done
    required this.arcPercent, // Done
    required this.arcWidth,  // Done
    required this.arcSegmentsRounded, // Done
    required this.dialogSolidBackground, // Done
    required this.appBackgroundSolid,
    required this.appBackground,
    required this.customBackgroundBlur,
    required this.customBackgroundPath,
    required this.mainMenuStyle  //Done
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
    required int mainMenuStyle
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
      mainMenuStyle: mainMenuStyle
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
    required int mainMenuStyle
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
      mainMenuStyle: mainMenuStyle
    );

    return instance;
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
}
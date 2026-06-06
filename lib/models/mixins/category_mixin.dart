import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/category_budget.dart';
import 'package:jne_household_app/models/settings.dart';

/// Category CRUD: insert, update, sort, reorder, and raw-category saves.
mixin CategoryMixin on ChangeNotifier {
  // ── State accessors ───────────────────────────────────────────────────────
  Settings get settings;
  List<Category> get rawCategories;
  set rawCategories(List<Category> v);
  List<CategoryBudget> get categories;
  double get notAssignedBudget;

  bool get sharedDbConnected;
  bool get syncInProgress;

  // ── Methods called on BudgetState / other mixins ──────────────────────────
  Future<void> loadBudgets({int? overrideRange});
  void calcNotAssignedBudget();
  Future<void> saveWidgetData(String id, dynamic data);
  Future<void> syncSharedDb({bool manual = false, bool changeKey = false});

  // ── Implementation ────────────────────────────────────────────────────────

  Future<int> insertCategory(Category category) async {
    final newPos = rawCategories.length;
    category.save();
    rawCategories.add(category);
    categories.add(CategoryBudget(
      categoryId: category.category.id!,
      category: category.category.name,
      budget: category.budget,
      spent: 0.0,
      color: colorFromHex(category.category.color)!,
      position: newPos,
      overrideBankAccount: category.categoryBudgetsPlain.first.overrideBankAccount,
    ));
    sortRawCategories();
    sortCategories();
    calcNotAssignedBudget();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) syncSharedDb();
    _pushCategoryWidget();
    return category.category.id!;
  }

  void updateCategory(CategoryBudget oldCategory, CategoryBudget newCategory) {
    final index = categories.indexOf(oldCategory);
    if (index != -1) {
      categories[index] = newCategory;
      notifyListeners();
    }
    _pushCategoryWidget();
  }

  void sortCategories() {
    categories.sort((a, b) => b.position.compareTo(a.position));
    _pushCategoryWidget();
  }

  void sortRawCategories() {
    rawCategories.sort((a, b) => b.category.position.compareTo(a.category.position));
  }

  Future<void> updateRawCategory(Category updatedCategory) async {
    await updatedCategory.save();
    rawCategories = await DatabaseHelper().getCategories(settings.filterBudget);
    await loadBudgets();
    calcNotAssignedBudget();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
    _pushCategoryWidget();
  }

  Future<void> saveCategoryOrder() async {
    final positions = <Map<String, int>>[];
    for (final cat in rawCategories) {
      positions.add({"id": cat.category.id!, "pos": cat.category.position});
      final cb = categories.firstWhere((c) => c.categoryId == cat.category.id);
      cb.position = cat.category.position;
    }
    await DatabaseHelper().updatePositions(positions);
    sortRawCategories();
    sortCategories();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  double getCategoryBudget(String category) {
    if (category == "__undefined_category_name__") return notAssignedBudget;
    try {
      return categories
          .firstWhere((item) => item.category == category,
              orElse: () => throw Exception('Category not found'))
          .budget;
    } catch (_) {
      return notAssignedBudget;
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _pushCategoryWidget() {
    if (Platform.isAndroid || Platform.isIOS) {
      final list = categories.map((c) => c.toWidgetData(notAssignedBudget)).toList();
      saveWidgetData("categoryList", jsonEncode(list));
    }
  }
}

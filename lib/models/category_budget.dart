import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/services/brightness.dart';

class CategoryBudget {
  String category;
  int categoryId;
  double budget;
  double spent;
  int position;
  Color color;

  CategoryBudget({
    required this.category,
    required this.categoryId,
    required this.budget,
    required this.spent,
    required this.position,
    this.color = Colors.grey
  });

  Map<String, Object> toWidgetData(double unassignedBudget) {
    Color textColor = getTextColor(color, 0);

    return {
      "id": categoryId,
      "name": categoryId == -1 ? I18n.translate("unassigned") : category,
      "total": I18n.normalizeValueString(categoryId == -1 ? unassignedBudget : budget),
      "fraction": I18n.normalizeValueString(spent),
      "colorR": (color.r * 255.0).round() & 0xff,
      "colorG": (color.g * 255.0).round() & 0xff,
      "colorB": (color.b * 255.0).round() & 0xff,
      "colorA": (color.a * 255.0).round() & 0xff,
      "textColorR": (textColor.r * 255.0).round() & 0xff,
      "textColorG": (textColor.g * 255.0).round() & 0xff,
      "textColorB": (textColor.b * 255.0).round() & 0xff,
      "textColorA": (textColor.a * 255.0).round() & 0xff,
    };
  }
}
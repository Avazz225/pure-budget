
import 'package:flutter/material.dart';

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
}
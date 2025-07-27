import 'package:flutter/material.dart';

class Category {
  final int id;
  String name;
  double budget;
  Color color;
  int position;

  Category({
    required this.id,
    required this.name,
    required this.budget,
    required this.color,
    required this.position
  });
}
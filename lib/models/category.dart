import 'package:jne_household_app/models/category_budget_plain.dart';
import 'package:jne_household_app/models/category_plain.dart';

class Category {
  double budget;
  List<CategoryBudgetPlain> categoryBudgetsPlain;
  CategoryPlain category;


  Category({
    required this.budget,
    required this.categoryBudgetsPlain,
    required this.category
  });

  Future<double> getBudget(int intervalId) async {
    double totalBudget = 0.0;
    for (CategoryBudgetPlain cb in categoryBudgetsPlain) {
      totalBudget += await cb.getBudgetForInterval(intervalId);
    }
    return totalBudget;
  }

  save() {
    category.save();
    for (CategoryBudgetPlain c in categoryBudgetsPlain) {
      c.save();
    }
  }
}
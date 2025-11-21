import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/realized_categroybudgets.dart';

class CategoryBudgetPlain {
  int? id;
  late int categoryId;
  late int accountId;
  late double budget;
  dynamic overrideBankAccount;

  CategoryBudgetPlain(Map<String, dynamic> values) {
    if (values.keys.contains("overrideBankAccount")) {
      if (values['overrideBankAccount'] == null) {
        overrideBankAccount = null;
      } else {
        overrideBankAccount = values['overrideBankAccount'] is int ? values['overrideBankAccount'] : int.tryParse(values['overrideBankAccount']) ?? values['overrideBankAccount'];
      }
    }
    if (values.keys.contains("id")) {
      id = values['id'] is int ? values['id'] : int.tryParse(values['id']) ?? values['id'];
    }

    categoryId = values['categoryId'] is int ? values['categoryId'] : int.tryParse(values['categoryId']) ?? values['categoryId'];
    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId']) ?? values['accountId'];
    budget = values['budget'] is double ? values['budget'] : double.tryParse(values['budget']) ?? values['budget'];
  }

  Future<double> getBudgetForInterval(int intervalId) async {
    final rcb = await DatabaseHelper().genericSelect('realizedCategoryBudgets', limit: 1, filter: 'categoryId = ? AND accountId = ? AND intervalId = ?', filterArgs: [categoryId, accountId, intervalId]);
    if (rcb.isNotEmpty) {
      return rcb.first['budget'] is double ? rcb.first['budget'] : double.tryParse(rcb.first['budget'].toString()) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (overrideBankAccount != null) 'overrideBankAccount': overrideBankAccount,
      "id": id,
      'categoryId': categoryId,
      'accountId': accountId,
      'budget': budget
    };
  }

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("categoryBudgets", values);
    } else {
      await DatabaseHelper().genericUpdate("categoryBudgets", values);

      // get latest realized category budget and update its budget as well
      final rcb = RealizedCategoryBudgets((await DatabaseHelper().genericSelect(
        'realizedCategoryBudgets',
        filter: 'categoryId = ? AND accountId = ?',
        filterArgs: [categoryId, accountId],
        order: 'intervalId DESC',
        limit: 1
      )).first);
      rcb.budget = budget;
      await rcb.save();
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("categoryBudgets", id!);
  }
}
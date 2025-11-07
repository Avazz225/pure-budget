import 'package:jne_household_app/database_helper.dart';

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
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("categoryBudgets", id!);
  }
}
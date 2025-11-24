import 'package:jne_household_app/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class RealizedCategoryBudgets {
  int? id;
  late int intervalId;
  late int accountId;
  late int categoryId;
  late double budget;
  int? overrideBankAccount;

  RealizedCategoryBudgets(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    if (values.keys.contains("overrideBankAccount")) {
      if (values['overrideBankAccount'] != null) {
        overrideBankAccount = values['overrideBankAccount'] as int;
      }
    }

    intervalId = values['intervalId'] is int ? values['intervalId'] : int.tryParse(values['intervalId']) ?? values['intervalId'];
    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId']) ?? values['accountId'];
    categoryId = values['categoryId'] is int ? values['categoryId'] : int.tryParse(values['categoryId']) ?? values['categoryId'];
    budget = values['budget'] is double ? values['budget'] : double.tryParse(values['budget']) ?? values['budget'];
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (overrideBankAccount != null) 'overrideBankAccount': overrideBankAccount,
      'intervalId': intervalId,
      'accountId': accountId,
      'budget': budget,
      'categoryId': categoryId
    };
  }

  Future<void> save({Database? dbObj}) async {
    final db = dbObj ?? await DatabaseHelper().database;
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("realizedCategoryBudgets", values, dbObj: db);
    } else {
      await DatabaseHelper().genericUpdate("realizedCategoryBudgets", values, dbObj: db);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("realizedCategoryBudgets", id!);
  }
}
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/logger.dart';
import 'package:sqflite/sqflite.dart';

class Expense {
  int? id;
  late int accountId;
  late int categoryId;
  late DateTime date;
  late String description;
  late double amount;
  late bool auto;
  late int autoId;

  Expense(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId'] ?? "-1") ?? -1;
    categoryId = values['categoryId'] is int ? values['categoryId'] : int.tryParse(values['categoryId'] ?? "-1") ?? -1;
    description = values['description'] as String;
    date = DateTime.parse(values['date']);
    amount = values['amount'] is double ? values['amount'] : double.tryParse(values['amount'] ?? "0.0") ?? 0.0;
    auto = values['auto'] == 1 || values['auto'] == "1";
    autoId = values['autoId'] is int ? values['autoId'] : int.tryParse(values['autoId'] ?? "-1") ?? -1;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'description': description,
      'date': formatForSqlite(date),
      'amount': amount,
      'auto': auto ? 1 : 0,
      'autoId': autoId,
    };
  }

  Future<void> save({Database? dbObj}) async {
    final db = dbObj ?? await DatabaseHelper().database;
    final values = toMap();
    if (id == null) {
      Logger().debug("inserting new expense");
      id = await DatabaseHelper().genericInsert("expenses", values, dbObj: db);
    } else {
      await DatabaseHelper().genericUpdate("expenses", values, dbObj: db);
    }
  }

  Future<void> delete({Database? dbObj}) async {
    await DatabaseHelper().genericDelete("expenses", id!, dbObj: dbObj);
  }
}
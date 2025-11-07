import 'package:jne_household_app/database_helper.dart';

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

    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId']) ?? values['accountId'];
    categoryId = values['categoryId'] is int ? values['categoryId'] : int.tryParse(values['categoryId']) ?? values['categoryId'];
    description = values['description'] as String;
    date = DateTime.parse(values['date']);
    amount = values['amount'] is double ? values['amount'] : double.tryParse(values['amount']) ?? 0.0;
    auto = values['auto'] == 1 || values['auto'] == "1";
    autoId = values['autoId'] is int ? values['autoId'] : int.tryParse(values['autoId']) ?? values['autoId'];
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

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("expenses", values);
    } else {
      await DatabaseHelper().genericUpdate("expenses", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("expenses", id!);
  }
}
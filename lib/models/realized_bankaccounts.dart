import 'package:jne_household_app/database_helper.dart';

class RealizedBankaccounts {
  int? id;
  late int intervalId;
  late int accountId;
  late double balance;
  late double income;

  RealizedBankaccounts(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    intervalId = values['intervalId'] is int ? values['intervalId'] : int.tryParse(values['intervalId']) ?? values['intervalId'];
    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId']) ?? values['accountId'];
    balance = values['balance'] is double ? values['balance'] : double.tryParse(values['balance']) ?? values['balance'];
    income = values['income'] is double ? values['income'] : double.tryParse(values['income']) ?? values['income'];
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'intervalId': intervalId,
      'accountId': accountId,
      'balance': balance,
      'income': income
    };
  }

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("realizedBankaccounts", values);
    } else {
      await DatabaseHelper().genericUpdate("realizedBankaccounts", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("realizedBankaccounts", id!);
  }
}
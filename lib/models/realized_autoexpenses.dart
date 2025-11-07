import 'package:jne_household_app/database_helper.dart';

class RealizedAutoexpenses {
  int? id;
  late int intervalId;
  late int autoexpenseId;
  late int expenseId;

  RealizedAutoexpenses(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    intervalId = values['intervalId'] is int ? values['intervalId'] : int.tryParse(values['intervalId']) ?? values['intervalId'];
    autoexpenseId = values['autoexpenseId'] is int ? values['autoexpenseId'] : int.tryParse(values['autoexpenseId']) ?? values['autoexpenseId'];
    expenseId = values['expenseId'] is int ? values['expenseId'] : int.tryParse(values['expenseId']) ?? values['expenseId'];
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'intervalId': intervalId,
      'autoexpenseId': autoexpenseId,
      'expenseId': expenseId
    };
  }

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("realizedAutoexpenses", values);
    } else {
      await DatabaseHelper().genericUpdate("realizedAutoexpenses", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("realizedAutoexpenses", id!);
  }
}
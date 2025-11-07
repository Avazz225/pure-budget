import 'package:jne_household_app/database_helper.dart';

class Interval {
  int? id;
  late int accountId;
  late DateTime start;
  late DateTime end;

  Interval(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId']) ?? values['accountId'];
    start =  DateTime.parse(values['start']);
    end =  DateTime.parse(values['end']);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'accountId': accountId,
      'start': formatForSqlite(start),
      'end': formatForSqlite(end)
    };
  }

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("intervals", values);
    } else {
      await DatabaseHelper().genericUpdate("intervals", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("intervals", id!);
  }
}
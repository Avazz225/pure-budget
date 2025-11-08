import 'package:jne_household_app/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class PBInterval {
  int? id;
  late int accountId;
  late DateTime start;
  late DateTime end;

  PBInterval(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    accountId = values['accountId'] is int ? values['accountId'] : int.tryParse(values['accountId']) ?? values['accountId'];
    start =  values['start'] is DateTime ? values['start'] : DateTime.parse(values['start']);
    end =  values['end'] is DateTime ? values['end'] : DateTime.parse(values['end']);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'accountId': accountId,
      'start': formatForSqlite(start),
      'end': formatForSqlite(end)
    };
  }

  Future<void> save({Database? dbObj}) async {
    final db = dbObj ?? await DatabaseHelper().database;
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("intervals", values, dbObj: db);
    } else {
      await DatabaseHelper().genericUpdate("intervals", values, dbObj: db);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("intervals", id!);
  }
}
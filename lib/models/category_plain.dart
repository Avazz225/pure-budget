import 'package:jne_household_app/database_helper.dart';

class CategoryPlain {
  int? id;
  late String name;
  late String color;
  late int position;

  CategoryPlain(Map<String, dynamic> values) {
    if (values.keys.contains("id")) {
      id = values['id'] as int;
    }

    name = values['name'] as String;
    position = values['position'] is int ? values['position'] : int.tryParse(values['position']) ?? values['position'];
    color = values['color'] as String;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'position': position,
      'color': color
    };
  }

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("categories", values);
    } else {
      await DatabaseHelper().genericUpdate("categories", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("categories", id!);
  }
}
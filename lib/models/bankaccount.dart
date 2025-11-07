import 'package:jne_household_app/database_helper.dart';

class BankAccount {
  int? id;
  String name;
  double balance;
  double income;
  String description;
  String budgetResetPrinciple;
  int budgetResetDay;
  String lastSavingRun;
  double transfers;
  bool isCreditCard;
  int refillsFrom;
  String refillPrincipleMode;

  BankAccount({
    this.id,
    required this.name,
    required this.balance,
    required this.income,
    required this.description,
    required this.budgetResetPrinciple,
    required this.budgetResetDay,
    required this.lastSavingRun,
    required this.transfers,
    required this.isCreditCard,
    required this.refillsFrom,
    required this.refillPrincipleMode
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'balance': balance,
      'income': income,
      'description': description,
      'budgetResetPrinciple': budgetResetPrinciple,
      'budgetResetDay': budgetResetDay,
      'lastSavingRun': lastSavingRun,
      'transfers': transfers,
      'isCreditCard': isCreditCard,
      'refillsFrom': refillsFrom,
      'refillPrincipleMode': refillPrincipleMode
    };
  }

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("bankaccounts", values);
    } else {
      await DatabaseHelper().genericUpdate("bankaccounts", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("bankaccounts", id!);
  }
}

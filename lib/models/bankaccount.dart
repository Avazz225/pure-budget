import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/category_plain.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/realized_bankaccounts.dart';
import 'package:jne_household_app/models/realized_categroybudgets.dart';
import 'package:jne_household_app/models/reset_principles.dart';

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
      'isCreditCard': isCreditCard ? 1 : 0,
      'refillsFrom': refillsFrom,
      'refillPrincipleMode': refillPrincipleMode
    };
  }

  Future<void> save() async {
    final values = toMap();
    final dbObj = await DatabaseHelper().database;
    if (id == null) {
      id = await DatabaseHelper().genericInsert("bankaccounts", values, dbObj: dbObj);
      final PBInterval currentInterval = getDateRangeForPrinciple({"principle": budgetResetPrinciple, "day": budgetResetDay}, id!);
      await currentInterval.save(dbObj: dbObj);

      final List<CategoryPlain> cats = await DatabaseHelper().getCategoriesPlain();
      for (CategoryPlain c in cats) {
        final newRCB = RealizedCategoryBudgets({
          'intervalId': currentInterval.id!,
          'accountId': id!,
          'budget': 0,
          'categoryId': c.id!
        });
        await newRCB.save(dbObj: dbObj);
      }
    } else {
      await DatabaseHelper().genericUpdate("bankaccounts", values, dbObj: dbObj);
      
      // update current interval
      final PBInterval currentInterval = await DatabaseHelper().getIntervals(dbObj: dbObj, onlyFirst: true, filter: "accountId = ?", filterArgs: [id], order: "id DESC");
      currentInterval.end = getDateRangeForPrinciple({"principle": budgetResetPrinciple, "day": budgetResetDay}, id!).end;
      await currentInterval.save(dbObj: dbObj);

      // update latest realized bankaccount
      final rba = RealizedBankaccounts((await DatabaseHelper().genericSelect(
        'realizedBankaccounts',
        filter: 'accountId = ? and intervalId = ?',
        filterArgs: [id, currentInterval.id],
        order: 'intervalId DESC',
        limit: 1
      )).first);

      rba.income = income;
      rba.balance = balance;
      await rba.save(dbObj: dbObj);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("bankaccounts", id!);
  }
}

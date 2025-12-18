import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/services/auto_booking.dart';
import 'package:sqflite/sqflite.dart';

class AutoExpense {
  int? id;
  int categoryId;
  double amount;
  String description;
  String bookingPrinciple;
  int bookingDay;
  String principleMode;
  int receiverAccountId;
  bool moneyFlow;
  int accountId;
  bool ratePayment;
  int? rateCount;
  double? firstRateAmount;
  double? lastRateAmount;

  AutoExpense({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.bookingPrinciple,
    required this.bookingDay,
    required this.principleMode,
    required this.accountId,
    required this.moneyFlow,
    required this.receiverAccountId,
    required this.ratePayment,
    this.rateCount,
    this.firstRateAmount,
    this.lastRateAmount
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (rateCount != null) "rateCount": rateCount,
      if (firstRateAmount != null) "firstRateAmount": firstRateAmount,
      if (lastRateAmount != null) "lastRateAmount": lastRateAmount,

      "categoryId": categoryId,
      "amount": amount,
      "description": description,
      "bookingPrinciple": bookingPrinciple,
      "bookingDay": bookingDay,
      "principleMode": principleMode,
      "receiverAccountId": receiverAccountId,
      "moneyFlow": moneyFlow,
      "accountId": accountId,
      "ratePayment": ratePayment
    };
  }

  Future<void> save(PBInterval currentInterval) async {
    final dbObj = await DatabaseHelper().database;
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("autoexpenses", values, dbObj: dbObj);
      await processUpcomingAE(currentInterval, dbObj, false);
    } else {
      await DatabaseHelper().genericUpdate("autoexpenses", values, dbObj: dbObj);
      await deleteUpcomingAE(dbObj);
      await processUpcomingAE(currentInterval, dbObj, false);
    }
  }

  Future<void> delete() async {
    final dbObj = await DatabaseHelper().database;
    if (id == null) {
      Logger().error("Didn't delete autoexpense. No id", tag: "autoexpense");
      return;
    } else {
      await DatabaseHelper().genericDelete("autoexpenses", id!, dbObj: dbObj);
      await deleteUpcomingAE(dbObj);
    }
  }

  Future<void> deleteUpcomingAE(Database dbObj) async {
    final realizedAutoexpenses = await DatabaseHelper().genericSelect("realizedAutoexpenses", filter: "autoexpenseId = ?", filterArgs: [id], dbObj: dbObj);
    for (final ae in realizedAutoexpenses) {
      final expense = Expense((await DatabaseHelper().genericSelect("expenses", filter: "accountId = ? AND categoryId = ? AND autoId = ?", filterArgs: [accountId, categoryId, id], dbObj: dbObj)).first);
      if (expense.date.isAfter(DateTime.now())) {  
        await expense.delete(dbObj: dbObj);
        await DatabaseHelper().genericDelete("realizedAutoexpenses", ae["id"], dbObj: dbObj);
      }
    }
  }

  Future<void> processUpcomingAE(PBInterval interval, Database dbObj, bool startIsInterval) async {
    await createBookings([this], false, interval, dbObj, startIsInterval);
  }
}
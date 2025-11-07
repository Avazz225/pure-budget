import 'package:jne_household_app/database_helper.dart';

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

  Future<void> save() async {
    final values = toMap();
    if (id == null) {
      id = await DatabaseHelper().genericInsert("autoexpenses", values);
    } else {
      await DatabaseHelper().genericUpdate("autoexpenses", values);
    }
  }

  Future<void> delete() async {
    await DatabaseHelper().genericDelete("autoexpenses", id!);
  }
}
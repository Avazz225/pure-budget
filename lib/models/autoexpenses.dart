class AutoExpense {
  final int id;
  int categoryId;
  double amount;
  String description;
  String bookingPrinciple;
  int bookingDay;
  String principleMode;
  int receiverAccountId;
  bool moneyFlow;
  int accountId;

  AutoExpense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.bookingPrinciple,
    required this.bookingDay,
    required this.principleMode,
    required this.accountId,
    required this.moneyFlow,
    required this.receiverAccountId
  });
}
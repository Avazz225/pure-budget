class BankAccount {
  final int id;
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
    required this.id,
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
}

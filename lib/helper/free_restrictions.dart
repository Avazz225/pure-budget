import 'dart:io';

const int maxAutoExpenses = 5;
const int maxCategories = 5;

const int maxFreeRanges = 6;
const int maxProRanges = 24;

const int maxFreeAccounts = 2;

const String proVersionProductId = "jjs.purebudget.pro";

// desktop vars
const desktopIsDefaultPro = false;

bool getProStatus(bool isPro) {
  if (isPro) return true;

  if (!(Platform.isAndroid || Platform.isIOS) && desktopIsDefaultPro) {
    return true;
  }

  return false;
}


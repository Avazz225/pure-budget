import 'dart:io';

import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';

String getIssueData(BudgetState state) {
  final logger = Logger();
  logger.debug("Collecting report information", tag: "report");
  String criticals = logger.getCriticalLog().join("\n");
  if (criticals == "") {
    criticals = "<No log data available>";
  }
  String platform = Platform.operatingSystem;
  String osVersion = Platform.operatingSystemVersion;
  

  String report = """
###################################
${I18n.translate("reportDoNotEdit")}

Issue reported at ${DateTime.now().toIso8601String()}

-----------------------------------
GENERAL INFO
  -> App version: $appVersion
  -> Platform: $platform
  -> OS version: $osVersion

-----------------------------------
APP CONFIG
  -> Pro status: ${(state.isPro || state.isDesktopPro) ? "true" : "false"}
    -> Desktop: ${state.isDesktopPro.toString()}
    -> General: ${state.isPro.toString()}
  -> Autoexpense count: ${state.autoExpenses.length.toString()}
  -> Bank account count: ${state.bankAccounts.length.toString()}
  -> Category count: ${state.categories.length.toString()}
  -> Currency: ${state.currency}
  -> Language: ${state.language}
  -> Lock app: ${state.lockApp.toString()}
  -> Money flow count: ${state.moneyFlows.length.toString()}
  -> Range count: ${state.budgetRanges.length.toString()}
  -> Shared database: ${(state.sharedDbUrl != "none")? "true": "false"}
  -> Use balance: ${state.useBalance.toString()}

-----------------------------------
APP LOG
""";
  return report + criticals;
}

String getMailTitle() {
  String platform = Platform.operatingSystem;
  return "Pure Budget Issue Report - $platform v. $appVersion";
}

List<String> reportIssueMailData(BudgetState state, String description) {
  return [
    getMailTitle(),
"""Issue Report

Description:
$description 

${getIssueData(state)}
"""];
}
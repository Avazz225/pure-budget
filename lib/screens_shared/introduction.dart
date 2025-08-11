import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/helper/default_values.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/export_import.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/main/autoexpenses.dart';
import 'package:jne_household_app/widgets_shared/background_painter.dart';
import 'package:jne_household_app/widgets_shared/main/add_category.dart';
import 'package:jne_household_app/widgets_shared/main/bank_accounts.dart';
import 'package:jne_household_app/widgets_shared/main/category_list.dart';
import 'package:provider/provider.dart';

class AppSetupScreen extends StatefulWidget {
  const AppSetupScreen({super.key});

  @override
  _AppSetupScreenState createState() => _AppSetupScreenState();
}

class _AppSetupScreenState extends State<AppSetupScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    final double bodyHeight = MediaQuery.of(context).size.height * 0.7;
    final largeBody = Theme.of(context).textTheme.bodyLarge;
    final smallHeadline = Theme.of(context).textTheme.headlineSmall;

    void onIntroEnd(BuildContext context) {
      budgetState.setSetupComplete();
    }

    Widget title([bool showSkip = true]) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            I18n.translate("appTitle"), 
            style: smallHeadline,
          ),
          showSkip ?
          TextButton(
            onPressed: () => onIntroEnd(context), 
            child: Text(I18n.translate("skip"))
          ) 
          :
          const SizedBox.shrink()
        ],
      );
    }

    void editCurrency(String currency){
      showDialog(
        context: context,
        builder: (context) {
          final TextEditingController currencyController = TextEditingController(text: currency);

          return AdaptiveAlertDialog(
            title: Text(I18n.translate("editCurrency")),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currencyController,
                    decoration: InputDecoration(labelText: I18n.translate("currency")),
                  )
                ],
              )
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(I18n.translate("cancel")),
              ),
              TextButton(
                onPressed: () async {
                  final settingsState = Provider.of<BudgetState>(context, listen: false);
                  await settingsState.updateCurrency(currencyController.text);
                  Navigator.of(context).pop();
                },
                child: Text(I18n.translate("save")),
              ),
            ],
          );
        },
      );
    }
    
    return Stack (
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BackgroundPainter(isDarkMode: Theme.of(context).brightness == Brightness.dark, context: context),
          ),
        ),
        IntroductionScreen(
          globalBackgroundColor: Colors.transparent,
          key: introKey,
          pages: [
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      I18n.translate("introS1Title", placeholders: {"appName": I18n.translate("appTitle")}),
                      style: smallHeadline,
                    ),
                    Column(
                      spacing: 20,
                      children: [
                        Text(
                          I18n.translate("introS1Body"),
                          style: largeBody,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => introKey.currentState?.skipToEnd(),
                              style: btnNegativeStyle,
                              child: Text(I18n.translate("no")),
                            ),
                            ElevatedButton(
                              onPressed: () => introKey.currentState?.next(), // Zur nächsten Seite
                              style: btnPositiveStyle,
                              child: Text(I18n.translate("yes"))
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox.shrink()
                  ],
                )
              ),
            ),
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS2Title")
                    ),
                    Column(
                      spacing: 20,
                      children: [
                        Text(
                          I18n.translate("introS2Body"),
                          style: largeBody,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => introKey.currentState?.next(),
                              style: btnNeutralStyle,
                              child: Text(I18n.translate("yes")),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                introKey.currentState?.animateScroll(3);
                              },
                              style: btnNeutralStyle,
                              child: Text(I18n.translate("no")),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox.shrink()
                  ]
                )
              ),
            ),
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS3Title")
                    ),
                    Column(
                      spacing: 20,
                      children: [
                        Text(
                          I18n.translate("introS3Body"),
                          style: largeBody,
                          textAlign: TextAlign.center,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await BackupManager.importDataFromFile();
                            await budgetState.reloadData();
                            introKey.currentState?.skipToEnd();
                          },
                          style: btnNeutralStyle,
                          child: Text(I18n.translate("pickFile")),
                        ),
                      ],
                    ),
                    const SizedBox.shrink()
                  ]
                )
              ),
            ),
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS4Title")
                    ),
                    Column(
                      spacing: 20,
                      children: [
                        Text(
                          I18n.translate("introS4Body"),
                          style: largeBody,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          budgetState.currency,
                          style: largeBody,
                        ),
                        Wrap(
                          spacing: 10, // Abstand zwischen den Buttons
                          runSpacing: 10, // Abstand zwischen den Reihen
                          children: defaultCurrencies.map((currency) {
                            return ElevatedButton(
                              onPressed: () {
                                budgetState.updateCurrency(currency);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currency != budgetState.currency ? Colors.transparent : Colors.green[600],
                                foregroundColor: Colors.white
                              ),
                              child: Text(currency),
                            );
                          }).toList() + [
                            ElevatedButton(
                              onPressed: () => editCurrency(budgetState.currency), 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: defaultCurrencies.contains(budgetState.currency) ? Colors.blue[600] : Colors.green[600],
                                foregroundColor: Colors.white
                              ),
                              child: const Icon(Icons.edit_rounded),
                        )
                          ],
                        )
                      ],
                    ),
                    const SizedBox.shrink()
                  ]
                )
              ),
            ),
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS5Title")
                    ),
                    SizedBox(
                      height: bodyHeight,
                      child: bankAccounts(context, budgetState, setState),
                    )
                  ]
                )
              ),
            ),
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 20,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS6Title")
                    ),
                    Text(
                      I18n.translate("introS6Body"),
                      style: largeBody,
                      textAlign: TextAlign.center,
                    ),
                    AddCategory(budgetState: budgetState, pro: getProStatus(budgetState.isPro)),
                    categoryList(budgetState, setState)
                  ]
                )
              )
            ),
            PageViewModel(
              titleWidget: title(),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 20,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS7Title")
                    ),
                    Text(
                      I18n.translate("introS7Body"),
                      style: largeBody,
                      textAlign: TextAlign.center,
                    ),
                    Expanded(
                    child: autoExpenseList(budgetState)
                    )
                  ]
                )
              ),
            ),
            PageViewModel(
              titleWidget: title(false),
              bodyWidget: SizedBox(
                height: bodyHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      style: smallHeadline,
                      I18n.translate("introS8Title")
                    ),
                    Column(
                      spacing: 20,
                      children: [
                        Text(
                          I18n.translate("introS8Body", placeholders: {"appName": I18n.translate("appTitle")}),
                          style: largeBody,
                          textAlign: TextAlign.center,
                        ),
                        ElevatedButton(
                          onPressed: () => onIntroEnd(context),
                          style: btnNeutralStyle,
                          child: Text(I18n.translate("introFinish")),
                        )
                      ],
                    ),
                    const SizedBox.shrink()
                  ]
                )
              ),
            ),
          ],
          onDone: () => onIntroEnd(context),
          showBackButton: true,
          showNextButton: true,
          showDoneButton: true,
          back: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          next: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          done: Text(I18n.translate("done"), style: const TextStyle(color: Colors.white),),
          dotsDecorator: DotsDecorator(
            size: const Size.square(10.0),
            activeSize: const Size(22.0, 10.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            activeColor: Colors.green[600]
          ),
          dotsFlex: 0,
        )
      ]
    );
  }
}

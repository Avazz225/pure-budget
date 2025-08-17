import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/background_gradients.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/widgets_shared/app_background.dart';
import 'package:jne_household_app/widgets_shared/buttons.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/home/category_list.dart';
import 'package:provider/provider.dart';

const int availableMainMenuDesignCount = 2;
const int availableAddExpenseStyleCount = 2;
const int availableArcStyleCount = 3;
const int categoryMainStyleCount = 2;

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _percentController = TextEditingController();

  late int _selectedMainMenuVariant;
  late int _selectedAddExpenseVariant;
  late int _selectedArcStyle;
  late int _selectedCategoryMainStyle;
  late bool _layoutMainVertical;
  late bool _arcSegmentsRounded;
  late double _arcWidth;
  late double _arcPercent;
  late bool _dialogSolidBackground;
  late bool _appBackgroundSolid;
  late bool _customBackgroundBlur;

  @override
  void initState() {
    super.initState();
    final designState = Provider.of<DesignState>(context, listen: false);
    _selectedMainMenuVariant = designState.mainMenuStyle; 
    _selectedAddExpenseVariant = designState.addExpenseStyle;
    _selectedArcStyle = designState.arcStyle;
    _selectedCategoryMainStyle = designState.categoryMainStyle;
    _layoutMainVertical = designState.layoutMainVertical;
    _arcSegmentsRounded = designState.arcSegmentsRounded;
    _arcWidth = (designState.arcWidth * 100).roundToDouble();
    _widthController.text = _arcWidth.round().toString();
    _arcPercent = designState.arcPercent.roundToDouble();
    _percentController.text = _arcPercent.round().toString();
    _dialogSolidBackground = designState.dialogSolidBackground;
    _appBackgroundSolid = designState.appBackgroundSolid;
    _customBackgroundBlur = designState.customBackgroundBlur;
  }

  bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  void showDialogPreview() {
    showDialog(
      context: context,
      builder: (context) {
        return AdaptiveAlertDialog(
          title: Text(I18n.translate("preview")),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(I18n.translate("done")),
            )
          ],
        );
      }
    );
  }

  void showCustomBackgroundImagePicker() async {
    final designState = Provider.of<DesignState>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        String? path = result.files.first.path;
        if (path != null) {
          designState.updateCustomBackgroundPath(path);
        }
      } else {
        // User hat abgebrochen
      }
    } catch (e) {
      Logger().error("Could not pick file: $e", tag: "customization");
    }
  }

  void showAppBackgroundPicker(){
    final designState = Provider.of<DesignState>(context, listen: false);
    final height = MediaQuery.of(context).size.height / 3;
    final width = MediaQuery.of(context).size.width / 3;
    showDialog(
      context: context, 
      builder: (context) {
        return AdaptiveAlertDialog(
          title: Text(I18n.translate("appBackground")),
          content: SingleChildScrollView(
            child: Column(
              children: 
                List.generate(gradients.length, (i) {
                  return GestureDetector(
                    onTap: () async {
                      await designState.updateCustomBackgroundPath("none");
                      await designState.updateAppBackground(i);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: height,
                        width: width,
                        child: AppBackground(imagePath: "none", gradientOption: i, blur: designState.customBackgroundBlur,)
                      )
                    )
                  );
                }
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(I18n.translate("done")),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    BudgetState budgetState = Provider.of<BudgetState>(context, listen: false);
    DesignState designState = Provider.of<DesignState>(context, listen: false);
    TextStyle smallHeadline = Theme.of(context).textTheme.headlineSmall!;
    TextStyle bigBody = Theme.of(context).textTheme.bodyLarge!;
    final button = (_selectedMainMenuVariant == 0) ? glassButton : flatButton;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "Ur Budget",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8,),
            Text("(${I18n.translate("customization")})"),
          ],
        ) 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (isDesktop()) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(I18n.translate("layoutMainVertical"), style: smallHeadline),
                            Switch(
                              value: _layoutMainVertical,
                              onChanged: (value) {
                                designState.updateLayoutMainVertical(value);
                                setState(() {
                                  _layoutMainVertical = value;
                                });
                              },
                              activeColor: Colors.green,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [ 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(I18n.translate("dialogSolidBackground"), style: smallHeadline),
                            Switch(
                              value: !_dialogSolidBackground,
                              onChanged: (value) {
                                designState.updateDialogSolidBackground(!value);
                                setState(() {
                                  _dialogSolidBackground = !value;
                                });
                              },
                              activeColor: Colors.green,
                            )
                          ],
                        ),
                        button(
                          context,
                          () {showDialogPreview();},
                          label: I18n.translate("showPreview")
                        ),
                        ]
                    )
                  )
                ),
              ],
              if (isDesktop()) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [
                        Text(I18n.translate("mainMenuStyle"), style: smallHeadline),
                        const SizedBox(height: 4),
                        buildVariantDropdown(
                          variantCount: availableMainMenuDesignCount,
                          selectedIndex: _selectedMainMenuVariant,
                          onChanged: (newIndex) {
                            if (newIndex != null) {
                              designState.updateMainMenuStyle(newIndex);
                              setState(() {
                                _selectedMainMenuVariant = newIndex;
                              });
                            }
                          },
                        ),
                        Card(
                          elevation: 50,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsetsGeometry.all(8),
                                child: Column (
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(I18n.translate("preview"), style: bigBody,),
                                    const SizedBox(height: 8),
                                    button(
                                      context,
                                      () {},
                                      label: I18n.translate("customization")
                                    )
                                  ]
                                )
                              )
                            ],
                          ),
                        ),
                      ]
                    )
                  )
                ),
              ],
              ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [ Text(I18n.translate("addExpenseStyle"), style: smallHeadline),
                        const SizedBox(height: 4),
                        buildVariantDropdown(
                          variantCount: availableAddExpenseStyleCount,
                          selectedIndex: _selectedAddExpenseVariant,
                          onChanged: (newIndex) {
                            if (newIndex != null) {
                              designState.updateAddExpenseStyle(newIndex);
                              setState(() {
                                _selectedAddExpenseVariant = newIndex;
                              });
                            }
                          },
                        ),
                        Card(
                          elevation: 50,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsetsGeometry.all(8),
                                child: Column (
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(I18n.translate("preview"), style: bigBody,),
                                    const SizedBox(height: 8),
                                    if (designState.addExpenseStyle == 0) 
                                    IconButton(
                                      icon: const Icon(Icons.add_rounded),
                                      onPressed: () {},
                                    ),
                                    if (designState.addExpenseStyle == 1)
                                    button(
                                      context,
                                      () {},
                                      label: I18n.translate("new")
                                    ) 
                                  ]
                                )
                              )
                            ],
                          ),
                        ),
                      ]
                    )
                  )
                ),
              ],
              ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [ Text(I18n.translate("categoryMainStyle"), style: smallHeadline),
                        const SizedBox(height: 4),
                        buildVariantDropdown(
                          variantCount: availableArcStyleCount,
                          selectedIndex: _selectedCategoryMainStyle,
                          onChanged: (newIndex) {
                            if (newIndex != null) {
                              designState.updateCategoryMainStyle(newIndex);
                              setState(() {
                                _selectedCategoryMainStyle = newIndex;
                              });
                            }
                          },
                        ),
                        listTile(
                          budgetState: budgetState,
                          designState: designState,
                          context: context,
                          unassigned: budgetState.categories.first.category == "__unassigned__",
                          category: budgetState.categories.first,
                          textColor: getTextColor(budgetState.categories.first.color, designState.categoryMainStyle, context),
                          currency: budgetState.currency,
                          buttonBuilder: button,
                          allSpent: false,
                          showExpensesBottomSheet: () => {},
                          onPressed: () => {}
                        ),
                      ]
                    )
                  )
                ),
              ],
              ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [ Text(I18n.translate("arcStyle"), style: smallHeadline),
                        const SizedBox(height: 4),
                        buildVariantDropdown(
                          variantCount: availableArcStyleCount,
                          selectedIndex: _selectedArcStyle,
                          onChanged: (newIndex) {
                            if (newIndex != null) {
                              designState.updateArcStyle(newIndex);
                              setState(() {
                                _selectedArcStyle = newIndex;
                              });
                            }
                          },
                        ),
                        if (_selectedArcStyle == 0) 
                        ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(I18n.translate("arcSegmentsRounded"), style: bigBody),
                              Switch(
                                value: _arcSegmentsRounded,
                                onChanged: (value) {
                                  designState.updateArcSegmentsRounded(value);
                                  setState(() {
                                    _arcSegmentsRounded = value;
                                  });
                                },
                                activeColor: Colors.green,
                              )
                            ],
                          ),
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text(I18n.translate("arcWidth"), style: bigBody),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: _arcWidth,
                                    min: 0,
                                    max: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        _widthController.text = (value.roundToDouble()).toStringAsFixed(0);
                                        _arcWidth = value.roundToDouble();
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      designState.updateArcWidth((value.roundToDouble() / 100));
                                    },
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: _widthController,
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (value) {
                                        final parsed = double.tryParse(value);
                                        if (parsed != null) {
                                          designState.updateArcWidth((parsed.roundToDouble() / 100));
                                          setState(() {
                                            _arcWidth = parsed.roundToDouble();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Text(I18n.translate("percent"), style: bigBody),
                                ],
                              )
                            ],
                          ),
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text(I18n.translate("arcPercent"), style: bigBody),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: _arcPercent,
                                    min: 0,
                                    max: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        _percentController.text = (value).toStringAsFixed(0);
                                        _arcPercent = value.roundToDouble();
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      designState.updateArcPercent(value.roundToDouble());
                                    },
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: _percentController,
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (value) {
                                        final parsed = double.tryParse(value);
                                        if (parsed != null) {
                                          designState.updateArcPercent(parsed.roundToDouble());
                                          setState(() {
                                            _arcPercent = parsed.roundToDouble();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Text(I18n.translate("percent"), style: bigBody),
                                ],
                              )
                            ],
                          )
                        ]
                      ]
                    )
                  )
                ),
              ],
              ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(I18n.translate("appBackgroundSolid")),
                            Switch(
                              value: _appBackgroundSolid,
                              onChanged: (value) {
                                designState.updateAppBackgroundSolid(value);
                                setState(() {
                                  _appBackgroundSolid = value;
                                });
                              },
                              activeColor: Colors.green,
                            )
                          ],
                        ),
                        if (!_appBackgroundSolid)
                        ...[
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8,
                            runSpacing: 8, 
                            children: [
                              button(
                                context,
                                () {showAppBackgroundPicker();},
                                label: I18n.translate("appBackground")
                              ),
                              button(
                                context,
                                () {showCustomBackgroundImagePicker();},
                                label: I18n.translate("customBackgroundPath")
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(I18n.translate("customBackgroundBlur")),
                              Switch(
                                value: _customBackgroundBlur,
                                onChanged: (value) {
                                  designState.updateCustomBackgroundBlur(value);
                                  setState(() {
                                    _customBackgroundBlur = value;
                                  });
                                },
                                activeColor: Colors.green,
                              )
                            ],
                          ),
                          Card(
                            elevation: 50,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsGeometry.all(8),
                                  child: Column (
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(I18n.translate("preview"), style: bigBody,),
                                      const SizedBox(height: 8),
                                      appBackgroundPreview(context, designState)
                                    ]
                                  )
                                )
                              ],
                            ),
                          ),
                        ]
                      ],
                    )
                  )
                )
              ]
            ],
          ),
        )
      ),
    );
  }
}

Widget appBackgroundPreview(context, designState) {
  return SizedBox(
    height: MediaQuery.of(context).size.height / 2,
    width: MediaQuery.of(context).size.width / 2,
    child: AppBackground(imagePath: designState.customBackgroundPath, gradientOption: designState.appBackground, blur: designState.customBackgroundBlur,)
  );
}

Widget buildVariantDropdown({
  required int variantCount,
  required int selectedIndex,
  required ValueChanged<int?> onChanged,
}) {
  return DropdownButton<int>(
    value: selectedIndex,
    isExpanded: true,
    items: List.generate(variantCount, (index) {
      return DropdownMenuItem<int>(
        value: index,
        child: Text(I18n.translate("variant", placeholders: {"id": "${index+1}"})),
      );
    }),
    onChanged: onChanged,
  );
}

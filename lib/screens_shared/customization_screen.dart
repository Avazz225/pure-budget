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
import 'package:jne_household_app/widgets_shared/dialogs/color_picker_dialog.dart';
import 'package:jne_household_app/widgets_shared/home/category_list.dart';
import 'package:provider/provider.dart';

const int availableMainMenuDesignCount = 2;
const int availableAddExpenseStyleCount = 2;
const int availableArcStyleCount = 3;
const int categoryMainStyleCount = 4;

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
  late double _blurIntensity;
  late String _customBackgroundPath;
  late int _appBackground;
  late Map<String,dynamic> _customGradient;

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
    _blurIntensity = designState.blurIntensity * 100;
    _customBackgroundPath = designState.customBackgroundPath;
    _appBackground = designState.appBackground;
    _customGradient = designState.customGradient;

    if (_customGradient.isEmpty || _customGradient['colors'].isEmpty) {
      _customGradient['colors'] = [Colors.blue, Colors.purple];
    }
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
          setState(() {
            _customBackgroundPath = path;
          });
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
                      setState(() {
                        _customBackgroundPath = "none";
                        _appBackground = i;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: height,
                        width: width,
                        child: AppBackground(imagePath: "none", gradientOption: i, blur: designState.customBackgroundBlur, customGradient: designState.customGradient)
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

  void showAppBackgroundCustomizer() {
    final designState = Provider.of<DesignState>(context, listen: false);
    final height = MediaQuery.of(context).size.height / 3;
    final width = MediaQuery.of(context).size.width / 3;

    showDialog(
      context: context, 
      builder: (context) {
        return AdaptiveAlertDialog(
          title: Text(I18n.translate("configCustomBackground")),
          content: StatefulBuilder(
          builder: (context, setState) {
            final List<Color> colors = List<Color>.from(_customGradient['colors'] ?? []);
            int type = _customGradient['type'] ?? 0;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(I18n.translate("gradientColors"), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: ReorderableListView(
                        shrinkWrap: true,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final color = colors.removeAt(oldIndex);
                            colors.insert(newIndex, color);
                            _customGradient['colors'] = colors;
                          });
                        },
                        children: [
                          for (int i = 0; i < colors.length; i++)
                            ListTile(
                              key: ValueKey("color_$i"),
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colors[i],
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: Text(I18n.translate("color", placeholders: {"index": (i + 1).toString()})),
                              trailing: (colors.length > 2) ? IconButton(
                                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    colors.removeAt(i);
                                    _customGradient['colors'] = colors;
                                  });
                                },
                              ): null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newColor = await openColorPickerDialog(context, Colors.white);
                        setState(() {
                          colors.add(newColor);
                          _customGradient['colors'] = colors;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(I18n.translate("addColor")),
                    ),
                    const SizedBox(height: 16),
                    Text(I18n.translate("gradientType"), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      min: 1,
                      max: 9,
                      divisions: 8,
                      value: type.toDouble() + 1,
                      label: (type + 1).toString(),
                      onChanged: (val) {
                        setState(() {
                          type = val.round() - 1;
                          _customGradient['type'] = type;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: height,
                        width: width,
                        child: AppBackground(imagePath: "none", gradientOption: -1, blur: designState.customBackgroundBlur, customGradient: _customGradient)
                      )
                    )
                  ]
                ),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await designState.updateCustomBackgroundPath("none");
                await designState.updateAppBackground(-1);
                await designState.updateCustomGradient(_customGradient);
                setState(() {
                  _customBackgroundPath = "none";
                  _appBackground = -1;
                });

                Navigator.of(context).pop();
              },
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
                          prefix: "mainMenuStyle",
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
                          prefix: "addExpenseStyle",
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
                          variantCount: categoryMainStyleCount,
                          selectedIndex: _selectedCategoryMainStyle,
                          prefix: "categoryMainStyle",
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
                          textColor: getTextColor(budgetState.categories.first.color, designState.categoryMainStyle, context: context),
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
                          prefix: "arcstyle",
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
                                () {showAppBackgroundCustomizer();},
                                label: I18n.translate("configCustomBackground")
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
                          if (_customBackgroundBlur)
                          ...[
                            Text(I18n.translate("blurIntensity")),
                            Slider(
                              value: _blurIntensity,
                              min: 0,
                              max: 600,
                              onChanged: (value) {
                                setState(() {
                                  _blurIntensity = value.roundToDouble();
                                });
                              },
                              onChangeEnd: (value) {
                                designState.updateBlurIntensity((value.roundToDouble() / 100));
                              },
                            ),
                          ],
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
                                      appBackgroundPreview(context, _customBackgroundPath, _appBackground, _customBackgroundBlur, _blurIntensity / 100, _customGradient)
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

Widget appBackgroundPreview(context, imagePath, appBackground, customBackgroundBlur, blurIntensity, customGradient) {
  return SizedBox(
    height: MediaQuery.of(context).size.height / 2,
    width: MediaQuery.of(context).size.width / 2,
    child: AppBackground(imagePath: imagePath, gradientOption: appBackground, blur: customBackgroundBlur, blurIntensity: blurIntensity, customGradient: customGradient)
  );
}

Widget buildVariantDropdown({
  required int variantCount,
  required int selectedIndex,
  required String prefix,
  required ValueChanged<int?> onChanged,
}) {
  return DropdownButton<int>(
    value: selectedIndex,
    isExpanded: true,
    items: List.generate(variantCount, (index) {
      return DropdownMenuItem<int>(
        value: index,
        child: Text(I18n.translate("${prefix}_variant_${index+1}")),
      );
    }),
    onChanged: onChanged,
  );
}

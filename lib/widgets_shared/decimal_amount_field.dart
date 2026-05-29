import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/services/text_formatter.dart';

/// Reusable decimal input field used across all expense/budget dialogs.
/// Handles locale-aware comma/dot swapping and cursor positioning.
class DecimalAmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelKey;
  final TextInputAction textInputAction;
  final void Function(void Function()) setState;
  final String? Function(String?)? validator;

  const DecimalAmountField({
    super.key,
    required this.controller,
    required this.labelKey,
    required this.setState,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
      decoration: InputDecoration(labelText: I18n.translate(labelKey)),
      validator: validator,
      onChanged: (value) => applyDecimalFormatting(value, controller, setState),
    );
  }
}

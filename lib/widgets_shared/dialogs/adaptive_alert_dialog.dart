import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:provider/provider.dart';

class AdaptiveAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  const AdaptiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final designState = Provider.of<DesignState>(context);
    if (designState.dialogSolidBackground) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: title,
        content: content,
        actions: actions,
      );
    } else {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor.withValues(alpha: .5), // halbtransparent
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: title,
          content: content,
          actions: actions,
        ),
      );
    }
  }
}
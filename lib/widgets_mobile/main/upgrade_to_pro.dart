import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/screens_mobile/mobile_in_app_purchase.dart';

Widget upgradeToProBtn(context, String key, Map<String, String> placeholders) {
  return ListTile(
    leading: const CircleAvatar(
      backgroundColor: Colors.deepOrangeAccent,
      foregroundColor: Colors.white,
      child: Icon(Icons.add_rounded),
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InAppPurchaseScreen(),
      ),
    ),
    title: Text(I18n.translate(key, placeholders: placeholders)),
  );
}

  
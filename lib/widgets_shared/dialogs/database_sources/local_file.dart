import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/shared_database/shared_database.dart';
import 'package:jne_household_app/widgets_shared/dialogs/connect_shared_db_dialog.dart';

Padding localFile (BuildContext context, BudgetState budgetState, Function handlePathSet) {
  final TextEditingController controller = TextEditingController();

  void openFilePicker() async {
    String? selectedPath = (await FilePicker.platform.getDirectoryPath()).toString();
    bool sharedDbExists = await checkRemoteDbExists(selectedPath);
    if (selectedPath != "none") {
      await connectSharedDbDialog(context, budgetState, selectedPath, sharedDbExists);
    }
  }
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: I18n.translate("selectOrEnterSharedPath"),
            ),
            onChanged: (selectedPath) {
              controller.text = selectedPath;
            },
            onSubmitted: (selectedPath) async {
              await handlePathSet();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: openFilePicker,
          icon: Icon(Icons.folder_rounded, semanticLabel: I18n.translate("browse"),),
        ),
      ],
    )
  );
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jne_household_app/services/receipt_service.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final ReceiptService _service = ReceiptService(baseCurrency: "€");
  ReceiptData? _data;

  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    ReceiptData data;
    if (filePath.toLowerCase().endsWith(".pdf")) {
      data = await _service.extractFromPdf(filePath);
    } else {
      data = await _service.extractFromImage(File(filePath));
    }

    _updateControllers(data);
  }

  void _updateControllers(ReceiptData data) {
    setState(() {
      _data = data;
      _merchantController.text = data.merchant;
      _amountController.text = data.amount;
      _currencyController.text = data.currency;
    });
  }

  void _save() {
    if (_data == null) return;

    final updatedData = ReceiptData(
      merchant: _merchantController.text,
      amount: _amountController.text,
      currency: _currencyController.text,
      qrLink: _data?.qrLink,
    );

    debugPrint("Saving: ${updatedData.merchant} | ${updatedData.amount} ${updatedData.currency}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Beleg gespeichert!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receipt Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _data == null
            ? const Center(child: Text("Datei auswählen, um zu starten"))
            : Column(
                children: [
                  TextField(
                    controller: _merchantController,
                    decoration: const InputDecoration(labelText: "Merchant"),
                  ),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: _currencyController,
                    decoration: const InputDecoration(labelText: "Currency"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _save, child: const Text("Save"))
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}

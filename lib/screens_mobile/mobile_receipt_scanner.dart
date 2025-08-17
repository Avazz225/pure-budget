import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/services/receipt_service.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';

class ReceiptPage extends StatefulWidget {
  final String baseCurrency;
  final BudgetState budgetState;
  const ReceiptPage({super.key, required this.baseCurrency, required this.budgetState});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  late final ReceiptService _service;
  final Logger _logger = Logger();
  bool available = false;

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _service = ReceiptService(baseCurrency: widget.baseCurrency);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    _cameraController = CameraController(cameras[0], ResolutionPreset.max);

    // 👉 Das Future auch speichern
    _initializeControllerFuture = _cameraController!.initialize();

    try {
      await _initializeControllerFuture;
      if (!mounted) return;
      _logger.debug("Camera init finished", tag: "OCR");
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        _logger.debug("Camera error: ${e.code}", tag: "OCR");
      } else {
        _logger.debug("Camera init failed: $e", tag: "OCR");
      }
    }
  }


  Future<void> _takePhoto() async {
    if (_cameraController == null) return;

    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      final file = File(image.path);

      final data = await _service.extractFromImage(file);
      await _updateControllers(data);
    } catch (e) {
      _logger.error("Error taking photo: $e", tag: "OCR");
    }
  }

  Future<void> _updateControllers(ReceiptData data) async {
    final selectedCat = widget.budgetState.selectedScanCategory;
    _logger.debug("Read data: amount -> ${data.amount}, selectedCategoryId -> $selectedCat", tag: "OCR");
    await showExpenseDialog(
      context: context,
      accountId: widget.budgetState.filterBudget,
      bankAccounts: widget.budgetState.bankAccounts,
      bankAccoutCount: widget.budgetState.bankAccounts.length,
      defaultVal: data.amount,
      category: widget.budgetState.rawCategories.where((c) => c.id == selectedCat).first.name,
      categoryId: selectedCat
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _cameraPreviewWidget() {
    final CameraController? controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return Text(
        I18n.translate("cameraError"),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        child: CameraPreview(
          controller,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(I18n.translate("receiptScanner"))),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                // 📸 Live Kamera Vorschau
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _cameraPreviewWidget(),
                )
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePhoto,
        child: const Icon(Icons.camera_alt_rounded),
      ),
    );
  }
}

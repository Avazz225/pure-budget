import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/services/receipt_service.dart';
import 'package:jne_household_app/widgets_shared/buttons.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';

class ReceiptPage extends StatefulWidget {
  final String baseCurrency;
  final BudgetState budgetState;
  final DesignState designState;
  final int? overrideCatId;
  final bool closeAfterSuccess;
  const ReceiptPage({super.key, required this.baseCurrency, required this.budgetState, required this.designState, this.overrideCatId, this.closeAfterSuccess = false});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  late final ReceiptService _service;
  final Logger _logger = Logger();
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _lastCapturedImage;
  bool _takingPhoto = false;


  @override
  void initState() {
    super.initState();
    _service = ReceiptService(baseCurrency: widget.baseCurrency);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = _cameraController!.initialize();

    try {
      await _initializeControllerFuture;
      if (!mounted) return;
      _logger.debug("Camera init finished", tag: "scan");
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        _logger.debug("Camera error: ${e.code}", tag: "scan");
      } else {
        _logger.debug("Camera init failed: $e", tag: "scan");
      }
    }
  }


  Future<void> _takePhoto() async {
    if (_cameraController == null) return;

    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      setState(() {
        _takingPhoto = true;
        _lastCapturedImage = image;
      });
      final file = File(image.path);

      final data = await _service.extractFromImage(file);
      await _updateControllers(data);
    } catch (e) {
      _logger.error("Error taking photo: $e", tag: "scan");
    } finally {
      setState(() => _takingPhoto = false);
    }
  }

  Future<void> _updateControllers(ReceiptData data) async {
    final selectedCat = widget.overrideCatId ?? widget.budgetState.selectedScanCategory;
    _logger.debug("Read data: amount -> ${data.amount}, selectedCategoryId -> $selectedCat", tag: "scan");
    await showExpenseDialog(
      context: context,
      accountId: widget.budgetState.filterBudget,
      bankAccounts: widget.budgetState.bankAccounts,
      bankAccoutCount: widget.budgetState.bankAccounts.length,
      defaultVal: data.amount,
      category: widget.budgetState.rawCategories.where((c) => c.id == selectedCat).first.name,
      categoryId: selectedCat
    );

    if (widget.closeAfterSuccess) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _cameraPreviewWidget() {
    final CameraController? controller = _cameraController;

    if (_takingPhoto && _lastCapturedImage != null) {
      return Image.file(File(_lastCapturedImage!.path), fit: BoxFit.cover);
    }

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
    final buttonBuilder = (widget.designState.mainMenuStyle == 0) ? glassButton : flatButton;
    return Scaffold(
      appBar: AppBar(title: Text(I18n.translate("receiptScanner"))),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
              onDoubleTap: _takePhoto,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _cameraPreviewWidget(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          style: Theme.of(context).textTheme.bodyLarge,
                          I18n.translate("photoInfo", placeholders: {"takePhoto": I18n.translate("takePhoto")})
                        ),
                        Text(
                          I18n.translate("or")
                        ),
                        buttonBuilder(
                          context,
                          () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null && result.files.single.path != null) {
                              final path = result.files.single.path!;
                              final data = await _service.extractFromPdf(path);
                              await _updateControllers(data);
                            }
                          },
                          label: I18n.translate("pickFile")
                        )
                      ],
                    )
                  )
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: buttonBuilder(
        context,
        _takePhoto,
        icon: Icons.camera_alt_rounded,
        label: I18n.translate("takePhoto")
      )
    );
  }
}

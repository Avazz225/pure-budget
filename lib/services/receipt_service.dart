import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:jne_household_app/helper/receipt_helper.dart';
import 'package:jne_household_app/logger.dart';
import 'package:pdf_image_renderer/pdf_image_renderer.dart';
import 'package:path_provider/path_provider.dart';


class ReceiptData {
  String amount;
  String currency;

  ReceiptData({
    required this.amount,
    required this.currency
  });
}

class ReceiptService {
  final String baseCurrency;
  final double? conversionToUsd;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final _logger = Logger();

  ReceiptService({required this.baseCurrency, this.conversionToUsd});

  // Extracts data from an image (camera/gallery)
  Future<ReceiptData> extractFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognisedText =
        await _textRecognizer.processImage(inputImage);

    return _parseText(recognisedText.text);
  }

  // Extracts data from a PDF
  Future<ReceiptData> extractFromPdf(String path) async {
    final pdfDoc = PdfImageRenderer(path: path);
    await pdfDoc.open();
    final StringBuffer buffer = StringBuffer();

    int pageCount = await  pdfDoc.getPageCount();

    for (int i = 1; i <= pageCount; i++) {
      await pdfDoc.openPage(pageIndex: i);
      final size = await pdfDoc.getPageSize(pageIndex: 0);
      // Render PDF-page as image
      final pageImage = await pdfDoc.renderPage(
          pageIndex: i,
          x: 0,
          y: 0,
          width: size.width,
          height: size.height,
          scale: 1,
          background: Colors.white,
        );

      // close the page again
      await pdfDoc.closePage(pageIndex: 0);

      final imgFile = await _saveTempImage(pageImage, size.width, size.height);
      final inputImage = InputImage.fromFile(imgFile);
      final recognisedText = await _textRecognizer.processImage(inputImage);
      buffer.writeln(recognisedText.text);
    }

    await pdfDoc.close();
    return _parseText(buffer.toString());
  }

  // Save PDF page as temporary image for OCR
  Future<File> _saveTempImage(Uint8List? uint8list, int width, int height) async {
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.png');

    final image = img.Image.fromBytes(width: width, height: height, bytes: uint8list!.buffer);
    final pngBytes = img.encodePng(image);

    await file.writeAsBytes(pngBytes);
    return file;
  }

  // Parsing logic: extract merchant, amount, currency
  ReceiptData _parseText(String text) {
    _logger.debug(text, tag: "OCR");
    double foundAmount = 0.0;
    String foundCurrency = baseCurrency;


    final matches = amountRegex.allMatches(text);
    double maxAmount = 0.0;

    for (final m in matches) {
      _logger.debug("Match: $m", tag: "OCR");
      final amountStr = (m.group(1) ?? "0").replaceAll(',', '.');
      final amount = double.tryParse(amountStr) ?? 0.0;
      if (amount > maxAmount) {
        maxAmount = amount;
        foundCurrency = normalizeCurrency(m.group(2) ?? baseCurrency);
      }
    }

    foundAmount = maxAmount;

    double convertedAmount = _convertToBase(foundAmount, foundCurrency, normalizeCurrency(baseCurrency), conversionToUsd);
    _logger.debug("Actual amount: $convertedAmount", tag: "OCR");
    return ReceiptData(
      amount: convertedAmount.toStringAsFixed(2),
      currency: baseCurrency,
    );
  }

  // Helperfunction: Convert to base currency
  double _convertToBase(double amount, String fromCurrency, String baseCurrency, double? conversionToUsd) {
    double rateToUsd = defaultConversionRates[fromCurrency] ?? 1.0;
    double usdAmount = amount * rateToUsd;
    double baseRate;
    _logger.debug("Extracted amount: $amount", tag: "OCR");
    _logger.debug("baseCurrency: $baseCurrency - foundCurrency: $fromCurrency", tag: "OCR");
    if (baseCurrency == fromCurrency) {
      return amount;
    }
    if (defaultConversionRates.containsKey(baseCurrency)) {
      baseRate = defaultConversionRates[baseCurrency]!;
    } else {
      baseRate = conversionToUsd ?? 1.0;
    }

    return usdAmount / baseRate;
  }
}

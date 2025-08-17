import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:jne_household_app/helper/receipt_helper.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:path_provider/path_provider.dart';


class ReceiptData {
  String merchant;
  String amount;
  String currency;
  String? qrLink;

  ReceiptData({
    required this.merchant,
    required this.amount,
    required this.currency,
    this.qrLink,
  });
}

class ReceiptService {
  final String baseCurrency;
  final double? conversionToUsd;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

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
    final pdfDoc = await PdfDocument.openFile(path);
    final StringBuffer buffer = StringBuffer();

    for (int i = 1; i <= pdfDoc.pageCount; i++) {
      final page = await pdfDoc.getPage(i);

      // Render PDF-page as image
      final pageImage = await page.render(
        fullWidth: page.width,
        fullHeight: page.height,
      );
      final imgFile = await _saveTempImage(pageImage);

      final inputImage = InputImage.fromFile(imgFile);
      final recognisedText = await _textRecognizer.processImage(inputImage);
      buffer.writeln(recognisedText.text);
    }

    await pdfDoc.dispose();
    return _parseText(buffer.toString());
  }

  // Save PDF page as temporary image for OCR
  Future<File> _saveTempImage(PdfPageImage pageImage) async {
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.png');

    final uint8list = pageImage.pixels;

    final image = img.Image.fromBytes(width: pageImage.width, height: pageImage.height, bytes: uint8list.buffer);
    final pngBytes = img.encodePng(image);

    await file.writeAsBytes(pngBytes);
    return file;
  }

  // Parsing logic: extract merchant, amount, currency
  ReceiptData _parseText(String text) {
    String foundMerchant = "__unknown_merchant__";
    double foundAmount = 0.0;
    String foundCurrency = baseCurrency;


    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      String amountStr = amountMatch.group(1)!.replaceAll(',', '.');
      foundAmount = double.tryParse(amountStr) ?? 0.0;

      String currency = amountMatch.group(2)!.toUpperCase();
      foundCurrency = normalizeCurrency(currency);
    }

    final merchantMatch = merchantRegex.firstMatch(text);
    if (merchantMatch != null) {
      foundMerchant = merchantMatch.group(0) ?? "__unknown_merchant__";
    }

    double convertedAmount = _convertToBase(foundAmount, foundCurrency, baseCurrency, conversionToUsd);

    return ReceiptData(
      merchant: foundMerchant,
      amount: convertedAmount.toStringAsFixed(2),
      currency: baseCurrency,
    );
  }

  // Helperfunction: Convert to base currency
  double _convertToBase(double amount, String fromCurrency, String baseCurrency, double? conversionToUsd) {
    double rateToUsd = defaultConversionRates[fromCurrency] ?? 1.0;
    double usdAmount = amount * rateToUsd;

    double baseRate;
    if (defaultConversionRates.containsKey(baseCurrency)) {
      baseRate = defaultConversionRates[baseCurrency]!;
    } else {
      baseRate = conversionToUsd ?? 1.0;
    }

    return usdAmount / baseRate;
  }
}

// lib/services/ocr_service.dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Runs on-device OCR across every scanned image path.
/// Single responsibility: images → concatenated plain text.
class OcrService {
  OcrService._();
  static final instance = OcrService._();


  /// Tolerance in pixels: blocks whose vertical centres are within this
  /// distance of each other are considered to be on the same line.
  static const double _lineThreshold = 50.0;

  /// Calls [onProgress] with (currentPage, totalPages) before each page
  /// so callers can update a step label.
  Future<String> recogniseAll(
    List<String> imagePaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final buffer = StringBuffer();

    for (int i = 0; i < imagePaths.length; i++) {
      onProgress?.call(i + 1, imagePaths.length);
      try {
        final result = await textRecognizer.processImage(
          InputImage.fromFilePath(imagePaths[i]),
        );

        final pageText = _blocksToLines(result);
        // print('---------------------------------------------------------------');
        // print('Page ${i + 1} OCR Text:\n$pageText');
        if (pageText.trim().isNotEmpty) {
          buffer.writeln(pageText.trim());
          buffer.writeln();
        }
      } catch (_) {
        // Skip pages that fail OCR – never abort the whole job.
      }
    }

    await textRecognizer.close();
    return buffer.toString().trim();
  }

  /// Groups [RecognizedText] blocks by their vertical centre, sorts each
  /// group left-to-right, and joins them with a space on the same line.
  String _blocksToLines(RecognizedText result) {
    // Collect every text line element with its bounding-box centre-Y.
    final List<({double centerY, double left, String text})> elements = [];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;
        final text = line.text.trim();
        if (text.isEmpty) continue;
        elements.add((
          centerY: rect.top + rect.height / 2,
          left: rect.left,
          text: text,
        ));
      }
    }

    if (elements.isEmpty) return '';

    // Sort top-to-bottom, then left-to-right within the same Y band.
    elements.sort((a, b) {
      final dy = a.centerY - b.centerY;
      if (dy.abs() > _lineThreshold) return dy.sign.toInt();
      return (a.left - b.left).sign.toInt();
    });

    // Merge elements that fall within [_lineThreshold] of each other into
    // a single output line.
    final List<List<({double centerY, double left, String text})>> rows = [];
    for (final el in elements) {
      if (rows.isEmpty ||
          (el.centerY - rows.last.first.centerY).abs() > _lineThreshold) {
        rows.add([el]);
      } else {
        rows.last.add(el);
      }
    }

    return rows.map((row) => row.map((e) => e.text).join(' ')).join('\n');
  }
}
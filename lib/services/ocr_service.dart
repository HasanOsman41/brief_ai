// lib/services/ocr_service.dart
import 'package:flutter_native_ocr/flutter_native_ocr.dart';

/// Runs on-device OCR across every scanned image path.
/// Single responsibility: images → concatenated plain text.
class OcrService {
  OcrService._();
  static final instance = OcrService._();

  final _ocr = FlutterNativeOcr();

  /// Calls [onProgress] with (currentPage, totalPages) before each page
  /// so callers can update a step label.
  Future<String> recogniseAll(
    List<String> imagePaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final buffer = StringBuffer();
    for (int i = 0; i < imagePaths.length; i++) {
      onProgress?.call(i + 1, imagePaths.length);
      try {
        final text = await _ocr.recognizeText(imagePaths[i]);
        if (text.trim().isNotEmpty) {
          buffer.writeln(text.trim());
          buffer.writeln();
        }
      } catch (_) {
        // Skip pages that fail OCR – never abort the whole job.
      }
    }
    return buffer.toString().trim();
  }
}

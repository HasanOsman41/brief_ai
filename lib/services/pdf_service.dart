// lib/services/pdf_service.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

/// Generates a PDF from scanned image paths and saves it somewhere the user can
/// reach.
///
/// Save-location strategy (in order):
///   1. Public `Downloads/BriefAI/` — only if `MANAGE_EXTERNAL_STORAGE` is
///      already granted. We never *request* this permission at runtime
///      because it requires a system-settings activity (not a normal grant
///      dialog) and Play Store policy heavily restricts it.
///   2. App-specific external storage (`Android/data/<pkg>/files/BriefAI/`)
///      — writable on every Android version, no permission needed,
///      visible in the device's Files app.
///   3. App documents directory — universal last-resort fallback.
class PdfService {
  PdfService._();
  static final instance = PdfService._();

  static const _folder = 'BriefAI';

  /// Returns the saved file path. Throws on unrecoverable I/O errors so the
  /// caller can surface a meaningful message.
  Future<String?> generateAndSave(List<String> imagePaths) async {
    final bytes = await _buildPdf(imagePaths);
    final fileName =
        'brief_ai_scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // 1) Public Downloads — only when "All files access" is already granted.
    if (Platform.isAndroid) {
      try {
        if (await Permission.manageExternalStorage.isGranted) {
          const downloads = '/storage/emulated/0/Download';
          final dir = Directory('$downloads/$_folder');
          if (!dir.existsSync()) await dir.create(recursive: true);
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          return file.path;
        }
      } catch (_) {
        // fall through to app-private storage
      }
    }

    // 2) App-specific external storage — no permission required, scoped to
    //    the app, but still visible in the system Files app.
    Directory? baseDir;
    if (Platform.isAndroid) {
      try {
        baseDir = await getExternalStorageDirectory();
      } catch (_) {
        baseDir = null;
      }
    }
    // 3) Final fallback.
    baseDir ??= await getApplicationDocumentsDirectory();

    final targetDir = Directory('${baseDir.path}/$_folder');
    if (!targetDir.existsSync()) await targetDir.create(recursive: true);

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<int>> _buildPdf(List<String> imagePaths) async {
    final doc = pw.Document();
    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return doc.save();
  }
}

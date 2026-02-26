// lib/services/pdf_service.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

/// Generates a PDF from scanned image paths and saves it to BriefAI folder.
/// Single responsibility: images → saved PDF file path.
class PdfService {
  PdfService._();
  static final instance = PdfService._();

  static const _folder = 'BriefAI';

  /// Returns saved file path, or null if permission was denied.
  Future<String?> generateAndSave(List<String> imagePaths) async {
    if (!await _hasPermission()) return null;

    final bytes = await _buildPdf(imagePaths);
    final dir   = await _saveDirectory();
    if (!dir.existsSync()) await dir.create(recursive: true);

    final file = File('${dir.path}/brief_ai_scan_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<int>> _buildPdf(List<String> imagePaths) async {
    final doc = pw.Document();
    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
      ));
    }
    return doc.save();
  }

  Future<bool> _hasPermission() async {
    if (Platform.isAndroid) {
      return (await Permission.storage.request()).isGranted;
    }
    return true;
  }

  Future<Directory> _saveDirectory() async {
    if (Platform.isAndroid) {
      const downloads = '/storage/emulated/0/Download';
      if (await Directory(downloads).exists()) {
        return Directory('$downloads/$_folder');
      }
      final ext = await getExternalStorageDirectory();
      return Directory('${ext!.path}/$_folder');
    }
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/$_folder');
  }
}

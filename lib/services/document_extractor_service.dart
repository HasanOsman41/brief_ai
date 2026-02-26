// lib/services/document_extractor_service.dart
import '../models/analysis_result.dart';

/// Extracts structured document info from raw OCR text.
/// Fully offline – no network calls.
/// Single responsibility: text → AnalysisResult.
class DocumentExtractorService {
  DocumentExtractorService._();
  static final instance = DocumentExtractorService._();

  // ── Category keywords ────────────────────────────────────────────────────

  static const _categoryKeywords = <String, List<String>>{
    'Invoice':    ['invoice','rechnung','faktura','betrag','mwst','ust','total','amount due','zahlungsziel'],
    'Government': ['jobcenter','finanzamt','bundesagentur','sgb','bescheid','behörde','sozialleistung','arbeitslosengeld','hartz','bafög','steuer','personalausweis'],
    'Medical':    ['diagnose','arzt','klinik','krankenhaus','rezept','patient','befund','therapie','medikament','medical','hospital','prescription','doctor'],
    'Legal':      ['vertrag','contract','agreement','klage','gericht','urteil','rechtsanwalt','notar','vollmacht','kündigung'],
    'Bank':       ['iban','bic','kontoauszug','bank','überweisung','lastschrift','zinsen','darlehen','kredit','transaction','account'],
    'Insurance':  ['versicherung','police','versicherungsnummer','schaden','prämie','insurance','policy','claim','coverage'],
    'Form':       ['antrag','formular','bitte ausfüllen','please fill','unterschrift','signature'],
    'Contract':   ['mietvertrag','arbeitsvertrag','kaufvertrag','leasing','laufzeit','vertragsdauer'],
    'Receipt':    ['quittung','kassenbon','receipt','bezahlt','paid','danke für ihren','thank you for'],
    'Letter':     ['sehr geehrte','dear','mit freundlichen grüßen','yours sincerely','betreff','subject:'],
  };

  static const _monthMap = <String, int>{
    'januar':1,'january':1,'februar':2,'february':2,'märz':3,'march':3,
    'april':4,'mai':5,'may':5,'juni':6,'june':6,'juli':7,'july':7,
    'august':8,'september':9,'oktober':10,'october':10,'november':11,
    'dezember':12,'december':12,
  };

  static final _datePat1 = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})');
  static final _datePat2 = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
  static final _datePat3 = RegExp(
    r'(\d{1,2})\.?\s*(Januar|Februar|März|April|Mai|Juni|Juli|August|'
    r'September|Oktober|November|Dezember|January|February|March|April|'
    r'May|June|July|August|September|October|November|December)\s*(\d{4})',
    caseSensitive: false,
  );
  static final _deadlineKw = RegExp(
    r'(bis zum|bis|fällig am|fällig|einzureichen bis|deadline[:\s]|'
    r'due by|due date|spätestens am|spätestens|abgabetermin|frist|'
    r'submit by|return by|termin)',
    caseSensitive: false,
  );
  static final _noiseLine = RegExp(
    r'^(datum|date|seite|page|an:|von:|from:|to:|fax|tel|email|www|\d+)$',
    caseSensitive: false,
  );
  static final _subjectPrefix = RegExp(
    r'^(betreff:|subject:|re:)\s*',
    caseSensitive: false,
  );

  // ── Public API ────────────────────────────────────────────────────────────

  AnalysisResult extract(String ocrText) {
    final lines = ocrText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return AnalysisResult(
      category:   _detectCategory(ocrText.toLowerCase()),
      title:      _extractTitle(lines),
      deadline:   _extractDeadline(ocrText),
      summary:    _extractSummary(ocrText, lines),
      rawOcrText: ocrText,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _detectCategory(String lower) {
    String best = 'Other';
    int bestScore = 0;
    for (final entry in _categoryKeywords.entries) {
      final score = entry.value.where(lower.contains).length;
      if (score > bestScore) { bestScore = score; best = entry.key; }
    }
    return best;
  }

  String _extractTitle(List<String> lines) {
    for (final line in lines) {
      if (_subjectPrefix.hasMatch(line.toLowerCase())) {
        return line.replaceFirst(_subjectPrefix, '').trim();
      }
    }
    for (final line in lines) {
      if (line.length >= 4 && !_noiseLine.hasMatch(line) && !RegExp(r'^\d').hasMatch(line)) {
        return line.length > 60 ? line.substring(0, 60) : line;
      }
    }
    return lines.isNotEmpty ? lines.first : '';
  }

  DateTime? _extractDeadline(String text) {
    final now = DateTime.now();

    DateTime? try1(RegExpMatch m) {
      final d = int.tryParse(m.group(1)!) ?? 0;
      final mo = int.tryParse(m.group(2)!) ?? 0;
      final y = int.tryParse(m.group(3)!) ?? 0;
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      return DateTime(y, mo, d);
    }
    DateTime? try2(RegExpMatch m) {
      final y = int.tryParse(m.group(1)!) ?? 0;
      final mo = int.tryParse(m.group(2)!) ?? 0;
      final d = int.tryParse(m.group(3)!) ?? 0;
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      return DateTime(y, mo, d);
    }
    DateTime? try3(RegExpMatch m) {
      final d = int.tryParse(m.group(1)!) ?? 0;
      final mo = _monthMap[m.group(2)!.toLowerCase()] ?? 0;
      final y = int.tryParse(m.group(3)!) ?? 0;
      if (mo < 1 || mo > 12) return null;
      return DateTime(y, mo, d);
    }

    final patterns = [
      (pat: _datePat1, parse: try1),
      (pat: _datePat2, parse: try2),
      (pat: _datePat3, parse: try3),
    ];

    // Pass 1: date near a deadline keyword
    for (final kw in _deadlineKw.allMatches(text)) {
      final window = text.substring(kw.start, (kw.end + 60).clamp(0, text.length));
      for (final p in patterns) {
        final m = p.pat.firstMatch(window);
        if (m != null) {
          final dt = p.parse(m);
          if (dt != null && dt.isAfter(now)) return dt;
        }
      }
    }
    // Pass 2: any future date
    for (final p in patterns) {
      for (final m in p.pat.allMatches(text)) {
        final dt = p.parse(m);
        if (dt != null && dt.isAfter(now)) return dt;
      }
    }
    return null;
  }

  String _extractSummary(String ocrText, List<String> lines) {
    final sentences = ocrText
        .replaceAll('\n', ' ')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length >= 20)
        .take(3)
        .toList();
    final raw = sentences.isNotEmpty ? sentences.join(' ') : lines.take(4).join(' ');
    return raw.length > 400 ? '${raw.substring(0, 400)}…' : raw;
  }
}

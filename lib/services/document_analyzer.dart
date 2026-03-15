/// BriefAI – Document Analyzer Service
///
/// Usage:
///   final result = DocumentAnalyzer.analyze(ocrText, lang: 'ar');
///
/// The returned [DocumentResult] contains:
///   - category      : matched category (null if unknown)
///   - title         : extracted or derived title
///   - summary       : short summary from OCR body
///   - deadline      : extracted date string (dd.MM.yyyy) or null
///   - nextSteps     : language-aware action list
///   - confidence    : high / medium / low / unknown
///   - matchedKeywords : keywords that triggered the match

import 'package:brief_ai/data/brief_ai_categories.dart';

import '../models/category_definition.dart';
import '../models/document_result.dart';

class DocumentAnalyzer {
  DocumentAnalyzer._();

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Analyse [ocrText] and return structured document information.
  ///
  /// [lang] controls which language is used for [DocumentResult.nextSteps]:
  ///   'ar' → Arabic   |   'de' (default) → German
  static DocumentResult analyze(String ocrText, {String lang = 'de'}) {
    if (ocrText.trim().isEmpty) {
      return DocumentResult(
        category: null,
        title: 'Unbekanntes Dokument',
        summary: '',
        deadline: null,
        nextSteps: const [],
        confidence: AnalysisConfidence.unknown,
        matchedKeywords: const [],
      );
    }

    final normText = _normalise(ocrText);

    // 1. Classify
    final classResult = _classify(normText);

    // 2. Extract fields
    final title = _extractTitle(ocrText);
    final deadline = _extractDeadline(ocrText);
    final summary = _extractSummary(ocrText, deadline);

    // 3. Next steps in requested language
    final nextSteps = classResult.category == null
        ? <String>[]
        : lang == 'ar'
        ? classResult.category!.nextStepsAr
        : classResult.category!.nextStepsDe;

    // 4. Build result
    final cat = classResult.category;
    return DocumentResult(
      category: cat == null
          ? null
          : DocumentCategory(
              id: cat.id,
              labelDe: cat.labelDe,
              labelAr: cat.labelAr,
              riskLevel: cat.riskLevel,
            ),
      title: title,
      summary: summary,
      deadline: deadline,
      nextSteps: nextSteps,
      confidence: classResult.confidence,
      matchedKeywords: classResult.matchedKeywords,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Lowercase + collapse whitespace
  static String _normalise(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Count how many of [keywords] appear in [normText].
  static ({int count, List<String> matched}) _countMatches(
    String normText,
    List<String> keywords,
  ) {
    final matched = <String>[];
    for (final kw in keywords) {
      if (normText.contains(_normalise(kw))) matched.add(kw);
    }
    return (count: matched.length, matched: matched);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLASSIFICATION
  // ─────────────────────────────────────────────────────────────────────────

  static ({
    CategoryDefinition? category,
    AnalysisConfidence confidence,
    List<String> matchedKeywords,
  })
  _classify(String normText) {
    int bestScore = 0;
    CategoryDefinition? bestCat;
    List<String> bestMatched = [];

    for (final cat in BriefAiCategories.all) {
      // Negative check – any negative keyword disqualifies this category
      final neg = _countMatches(normText, cat.negativeKeywords);
      if (neg.count > 0) continue;

      final decisive = _countMatches(normText, cat.decisiveKeywords);
      final supporting = _countMatches(normText, cat.supportingKeywords);

      final score = decisive.count * 100 + supporting.count * 10;

      if (score > bestScore) {
        bestScore = score;
        bestCat = cat;
        bestMatched = [...decisive.matched, ...supporting.matched];
      }
    }

    if (bestCat == null || bestScore == 0) {
      return (
        category: null,
        confidence: AnalysisConfidence.unknown,
        matchedKeywords: <String>[],
      );
    }

    final confidence = bestScore >= 100
        ? AnalysisConfidence.high
        : bestScore >= 20
        ? AnalysisConfidence.medium
        : AnalysisConfidence.low;

    return (
      category: bestCat,
      confidence: confidence,
      matchedKeywords: bestMatched,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DEADLINE EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────

  /// High-priority deadline triggers – these appear on the same line as the
  /// actionable date (payment deadline, submission deadline, appointment).
  static const _triggersHigh = [
    'bis spätestens',
    'bis zum',
    'spätestens bis',
    'bitte zahlen sie bis',
    'bitte reichen sie',
    'einreichen bis',
    'zahlungsfrist',
    'abgabe bis',
    'fristgerecht',
    'bitte erscheinen sie am',
    'erscheinen sie am',
  ];

  /// Medium-priority triggers – appointment dates, validity dates, etc.
  static const _triggersMed = [
    'termin am',
    'uhrzeit',
    'termin:',
    'beginnt am',
    'gültig bis',
    'endet am',
    'ab dem',
  ];

  static final _dateRegex = RegExp(r'\b(\d{2})\.(\d{2})\.(\d{4})\b');

  static String? _extractDeadline(String text) {
    final lines = text.split('\n');

    // Pass 1 – high-priority trigger on the same line
    for (final line in lines) {
      final ll = _normalise(line);

      // Skip pure header date lines like "Datum: 15.04.2026"
      final isDatumOnly =
          ll.startsWith('datum') &&
          ll.contains(':') &&
          !_triggersHigh.any((t) => ll.contains(t));
      if (isDatumOnly) continue;

      if (!_triggersHigh.any((t) => ll.contains(t))) continue;
      final m = _dateRegex.firstMatch(line);
      if (m != null) return m.group(0);
    }

    // Pass 2 – medium-priority trigger on the same line
    for (final line in lines) {
      final ll = _normalise(line);
      if (!_triggersMed.any((t) => ll.contains(t))) continue;
      final m = _dateRegex.firstMatch(line);
      if (m != null) return m.group(0);
    }

    // Pass 3 – earliest date anywhere in the text (fallback)
    final allMatches = _dateRegex.allMatches(text).toList();
    if (allMatches.isEmpty) return null;

    allMatches.sort((a, b) {
      final da = _parseDate(a.group(0)!);
      final db = _parseDate(b.group(0)!);
      return da.compareTo(db);
    });
    return allMatches.first.group(0);
  }

  static DateTime _parseDate(String ddmmyyyy) {
    final parts = ddmmyyyy.split('.');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TITLE EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────

  /// Known document title patterns – ordered from most specific to least.
  static const _titlePatterns = [
    // Jobcenter
    'Einladung zum Termin',
    'Aufforderung zur Mitwirkung',
    'Weiterbewilligungsantrag',
    'Veränderungsmitteilung',
    'Hauptantrag Bürgergeld',
    // Ausländerbehörde
    'Terminbestätigung',
    'Einladung zur persönlichen Vorsprache',
    'Aufforderung zur Vorlage von Unterlagen',
    'Nachforderung von Unterlagen',
    'Fiktionsbescheinigung',
    'Bewilligungsbescheid',
    'Ablehnungsbescheid',
    'Elektronischer Aufenthaltstitel',
    // Finanzamt
    'Einkommensteuerbescheid',
    'Steuerbescheid',
    'Steuererstattung',
    'Aufforderung zur Abgabe der Steuererklärung',
    'Verspätungszuschlag',
    'Vorauszahlung Einkommensteuer',
    'Steuernachzahlung',
    // Bank
    'Kontoauszug',
    'Überweisungsbestätigung',
    'Rücklastschrift',
    'Kreditkartenabrechnung',
    'Sicherheitswarnung',
    'Kontoüberziehung',
    // Rechnung / Mahnung / Inkasso
    'Letzte Mahnung',
    'Mahnung',
    'Zahlungserinnerung',
    'Inkasso-Forderung',
    'Vollstreckungsbescheid',
    'Mahnbescheid',
    'Zwangsvollstreckung',
    'Rechnung',
    // Wohnen
    'Kündigung Mietvertrag',
    'Fristlose Kündigung',
    'Mieterhöhung',
    'Nebenkostenabrechnung',
    'Wohnungsgeberbestätigung',
    'Mietbescheinigung',
    'Mietvertrag',
    'Kautionsabrechnung',
    'Kautionsrückzahlung',
    'Bestätigung der Kautionszahlung',
    'Kautionsvereinbarung',
    // Versicherung
    'Schadenmeldung',
    'Schadenregulierung',
    'Ablehnung der Schadenregulierung',
    'Beitragsrechnung',
    'Beitragsanpassung',
    'Kündigungsbestätigung',
    'Vertragsverlängerung',
    'Versicherungsschein',
    // Kfz
    'Elektronische Versicherungsbestätigung',
    // Verträge
    'Kündigung',
    'Arbeitsvertrag',
    'Ratenzahlungsvertrag',
    'Kaufvertrag',
    'Mitgliedschaftsvertrag',
    // Krankenkasse
    'Versicherungsbescheinigung',
    'Mitgliedsbescheinigung',
    'Familienversicherung',
    'Krankengeld',
    'Kassenwechsel',
  ];

  static String _extractTitle(String text) {
    // Search within the first 500 characters (document header region)
    final header = text.length > 500 ? text.substring(0, 500) : text;
    final headerLow = _normalise(header);

    for (final pattern in _titlePatterns) {
      if (headerLow.contains(_normalise(pattern))) return pattern;
    }

    // Fallback: first non-empty line
    final firstLine = text
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => 'Unbekanntes Dokument');
    return firstLine;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────

  static const _boilerplate = [
    'sehr geehrte',
    'sehr geehrter',
    'mit freundlichen grüßen',
    'hochachtungsvoll',
  ];

  static String _extractSummary(String text, String? deadline) {
    final sentences = text
        .split(RegExp(r'[\n.!?]'))
        .map((s) => s.trim())
        .where((s) {
          if (s.length < 20) return false;
          final sl = s.toLowerCase();
          return !_boilerplate.any((b) => sl.startsWith(b));
        })
        .take(3)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    var summary = sentences.length > 300
        ? '${sentences.substring(0, 297)}…'
        : sentences;

    if (deadline != null && !summary.contains(deadline)) {
      summary += ' Frist/Datum: $deadline.';
    }

    if (summary.isEmpty) {
      summary = text.substring(0, text.length.clamp(0, 200)).trim();
    }

    return summary;
  }
}

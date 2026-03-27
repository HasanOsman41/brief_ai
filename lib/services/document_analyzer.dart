/// BriefAI – Document Analyzer Service
///
/// Usage:
///   final result = DocumentAnalyzer.analyze(ocrText);
///
/// The returned [DocumentResult] contains:
///   - category.mainCategory : top-level group (MainCategory enum)
///   - category.id           : specific sub-category id
///   - category.labelKey     : l10n key → resolve via AppLocalizations
///   - title                 : extracted or derived title
///   - summary               : short summary from OCR body
///   - deadline              : extracted date string (dd.MM.yyyy) or null
///   - nextStepKeys          : ordered l10n keys, resolve via AppLocalizations
///   - confidence            : high / medium / low / unknown
///   - matchedKeywords       : keywords that triggered the match

import 'package:brief_ai/data/brief_ai_categories.dart';

import '../models/category_definition.dart';
import '../models/document_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeadlineResult – structured return value from extractDeadlineInfo()
// ─────────────────────────────────────────────────────────────────────────────

/// The type / urgency category of an extracted date.
enum DeadlineType {
  /// Personal appointment (Termin, Vorsprache, Einladung …)
  appointment,

  /// Document submission deadline (bis spätestens, einzureichen bis …)
  deadline,

  /// Legal objection deadline (Widerspruch, Rechtsbehelfsbelehrung …)
  legalDeadline,

  /// Payment due date (zahlen bis, fällig, überweisen …)
  paymentDeadline,

  /// Document / permit expiry (gültig bis, läuft ab am …)
  expiryDate,

  /// Document ready for collection (Abholung, abholbereit ab …)
  collectionDate,

  /// Relative deadline – no explicit date found (e.g. "innerhalb eines Monats")
  relativeLegal,
}

/// Structured result returned by [DocumentAnalyzer.extractDeadlineInfo].
class DeadlineResult {
  /// Parsed date. Null only for [DeadlineType.relativeLegal].
  final DateTime? date;

  /// Original dd.MM.yyyy string as it appeared in the OCR text.
  /// "RELATIVE" for relative legal deadlines.
  final String rawValue;

  /// Semantic type of this date.
  final DeadlineType type;

  /// Optional time string (HH:mm) – present for appointments only.
  final String? time;

  const DeadlineResult({
    required this.date,
    required this.rawValue,
    required this.type,
    this.time,
  });

  /// True when a concrete date was found.
  bool get hasDate => date != null;

  /// True when the deadline requires special relative handling.
  bool get isRelative => type == DeadlineType.relativeLegal;

  @override
  String toString() =>
      'DeadlineResult(type: $type, rawValue: $rawValue, date: $date, time: $time)';
}

// ─────────────────────────────────────────────────────────────────────────────
// DocumentAnalyzer
// ─────────────────────────────────────────────────────────────────────────────

class DocumentAnalyzer {
  DocumentAnalyzer._();

  // ───────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ───────────────────────────────────────────────────────────────────────────

  /// Analyse [ocrText] and return structured document information.
  static DocumentResult analyze(String ocrText) {
    // print('----------------------------------------------------------------');
    // print('OCR Text:\n$ocrText');
    if (ocrText.trim().isEmpty) {
      return const DocumentResult(
        category: null,
        title: 'Unbekanntes Dokument',
        summary: '',
        deadline: null,
        nextStepKeys: [],
        confidence: AnalysisConfidence.unknown,
        matchedKeywords: [],
      );
    }

    final normText = _normalise(ocrText);
    // 1. Classify
    final classResult = _classify(normText);

    // 2. Extract deadline (structured)
    final deadlineResult = extractDeadlineInfo(ocrText);

    // 3. Extract summary
    final summary = _extractSummary(ocrText, deadlineResult?.rawValue);

    // 4. Next step keys
    final nextStepKeys = classResult.category?.nextStepKeys ?? const <String>[];

    // 5. Build result
    final cat = classResult.category;
    return DocumentResult(
      category: cat == null
          ? null
          : DocumentCategory(
              id: cat.id,
              labelKey: cat.labelKey,
              riskLevel: cat.riskLevel,
              mainCategory: cat.mainCategory,
            ),
      title: cat?.labelKey ?? 'categoryOther',
      summary: summary,
      deadline: deadlineResult?.rawValue == 'RELATIVE'
          ? null
          : deadlineResult?.date.toString(),
      nextStepKeys: nextStepKeys,
      confidence: classResult.confidence,
      matchedKeywords: classResult.matchedKeywords,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PUBLIC: extractDeadlineInfo
  // ───────────────────────────────────────────────────────────────────────────

  /// Extracts the single most important date from [ocrText].
  ///
  /// This is a convenience wrapper around [extractAllDeadlines] that returns
  /// only the highest-priority result. Use [extractAllDeadlines] when you need
  /// every actionable date in the document (e.g. both a deadline AND an
  /// appointment on the same letter).
  ///
  /// Priority: legalDeadline > deadline > paymentDeadline >
  ///           appointment > expiryDate > collectionDate > fallback
  static DeadlineResult? extractDeadlineInfo(String text) {
    final all = extractAllDeadlines(text);
    return all.isEmpty ? null : all.first;
  }

  /// Extracts **all** actionable dates from [ocrText] and returns them sorted
  /// by priority (highest first).
  ///
  /// Ignored dates (letter date, birth date, application date, past
  /// correspondence, plain time periods) are never included.
  ///
  /// Example — a letter with an appointment AND a submission deadline returns:
  ///   [
  ///     DeadlineResult(type: deadline,     rawValue: "29.04.2026"),
  ///     DeadlineResult(type: appointment,  rawValue: "19.05.2026", time: "09:20"),
  ///   ]
  static List<DeadlineResult> extractAllDeadlines(String text) {
    final lines = text.split('\n');
    final results = <DeadlineResult>[];
    // Track raw date strings already added to avoid duplicates
    final seen = <String>{};

    void add(DeadlineResult? r) {
      if (r == null) return;
      if (seen.contains(r.rawValue)) return;
      seen.add(r.rawValue);
      results.add(r);
    }

    // ── STEP 0 – Relative legal deadline (no explicit date) ───────────────
    for (final line in lines) {
      if (_isIgnored(line)) continue;
      final ll = line.toLowerCase();
      if (_relativeKeywords.any(ll.contains) && _findDate(line) == null) {
        add(
          DeadlineResult(
            date: _relativeDate(),
            rawValue: 'RELATIVE',
            type: DeadlineType.relativeLegal,
          ),
        );
        break; // only one relative result needed
      }
    }

    // ── STEP 1–6 – Scan all lines for every type ──────────────────────────
    add(
      _scanLines(lines, _legalKeywords, DeadlineType.legalDeadline, seen: seen),
    );
    add(
      _scanLines(lines, _deadlineKeywords, DeadlineType.deadline, seen: seen),
    );
    add(
      _scanLines(
        lines,
        _paymentKeywords,
        DeadlineType.paymentDeadline,
        seen: seen,
      ),
    );
    add(_scanAppointment(lines, seen: seen));
    add(
      _scanLines(lines, _expiryKeywords, DeadlineType.expiryDate, seen: seen),
    );
    add(
      _scanLines(
        lines,
        _collectionKeywords,
        DeadlineType.collectionDate,
        seen: seen,
      ),
    );

    // ── STEP 6b – Expiry: regex pass for "gilt * bis" patterns ─────────────
    // Handles cases like "gilt diese voraussichtlich bis 31.07.2026" where
    // extra words between "gilt" and "bis" break simple contains() matching.
    for (final line in lines) {
      if (_isIgnored(line)) continue;
      if (!_expiryGiltRegex.hasMatch(line)) continue;
      final m = _findDate(line);
      if (m != null && !seen.contains(m.group(0)!)) {
        add(
          DeadlineResult(
            date: _parse(m.group(0)!),
            rawValue: m.group(0)!,
            type: DeadlineType.expiryDate,
          ),
        );
      }
    }

    // ── STEP 7 – Fallback only if nothing found at all ────────────────────
    if (results.isEmpty) {
      add(_fallback(lines));
    }

    // Sort by priority (enum ordinal = priority order as declared)
    results.sort((a, b) => a.type.index.compareTo(b.type.index));
    return results;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KEYWORD TABLES  (from OCR_Date_Rules_Professional.docx)
  // ───────────────────────────────────────────────────────────────────────────

  // ── Ignore triggers ───────────────────────────────────────────────────────
  static const _ignoreLinePatterns = [
    // Letter issue date
    r',\s*den\s+\d{2}\.\d{2}\.\d{4}', // "Bochum, den 07.04.2026" – comma required"
    r'^\s*Datum\s*:', // "Datum: 12.05.2026"
    r'\berstellt\s+am\b',
    r'\bausgestellt\s+am\b',
    // Application dates
    r'\bAntrag\s+vom\b',
    r'\bIhr\s+Antrag\s+vom\b',
    r'\bgestellt\s+am\b',
    r'\beingereicht\s+am\b',
    r'\bOnline-Antrag\s+vom\b',
    // Birth dates
    r'\bGeburtsdatum\b',
    r'\bgeboren\s+am\b',
    // Past correspondence
    r'\bSchreiben\s+vom\b',
    r'\bmit\s+Schreiben\s+vom\b',
    r'\bzuletzt\s+am\b',
    r'\bbereits\s+am\b',
    r'\bwurden\s+Sie\s+aufgefordert\b',
    r'\bmitgeteilt\s+am\b',
    // Time periods (vom…bis without gültig)
    r'\bim\s+Zeitraum\b',
    r'\bzwischen\b',
  ];

  // ── Relative legal (no explicit date) ────────────────────────────────────
  static const _relativeKeywords = [
    'innerhalb eines monats',
    'innerhalb von zwei wochen',
    'rechtsbehelfsbelehrung',
  ];

  // ── Legal deadline ────────────────────────────────────────────────────────
  static const _legalKeywords = [
    'widerspruch',
    'rechtsbehelfsbelehrung',
    'einspruch',
    'klagefrist',
    'frist zur einlegung',
    'innerhalb eines monats',
    'innerhalb von zwei wochen',
    'frist endet',
  ];

  // ── Hard deadline ─────────────────────────────────────────────────────────
  static const _deadlineKeywords = [
    'bis spätestens',
    'spätestens bis',
    'fristende',
    'frist endet am',
    'einzureichen bis',
    'nachzureichen bis',
    'reichen sie ein bis',
    'einreichen bis',
    'vorlegen bis',
    'vorlage bis',
    'unterlagen einreichen bis',
    'fristgerecht',
    'frist',
    'bis',
  ];

  // ── Payment deadline ──────────────────────────────────────────────────────
  static const _paymentKeywords = [
    'zahlungsfrist',
    'zahlbar bis',
    'zahlen bis',
    'überweisen sie bis',
    'überweisen sie den betrag bis',
    'betrag ist bis',
    'fällig',
    'gebühren sind bis',
    'kosten sind bis',
    'zahlung bis',
  ];

  // ── Appointment ───────────────────────────────────────────────────────────
  static const _appointmentKeywords = [
    'einladung zum termin',
    'terminbestätigung',
    'terminvereinbarung',
    'meldeaufforderung',
    'vorsprache erforderlich',
    'persönliche vorsprache',
    'persönlich vorzusprechen',
    'wir laden sie ein',
    'bitte erscheinen sie',
    'erscheinen sie',
    'vorsprache',
    'termin:',
    'termin am',
    'für den', // "für den 06.05.2026 um 08:30 Uhr vorgesehen"
    'ist für den',
    'vorgesehen',
    'termin',
    'termindaten',
    'einladung',
    'uhr', // "19.05.2026 um 09:20 Uhr"
  ];

  // ── Expiry date ───────────────────────────────────────────────────────────
  static const _expiryKeywords = [
    'aufenthaltstitel gültig bis',
    'duldung gültig bis',
    'fiktionsbescheinigung gültig bis',
    'gültig bis zum',
    'gültig bis',
    'gültigkeit',
    'ablaufdatum',
    'läuft ab am',
    'befristet bis',
    'gilt voraussichtlich bis',
    // Broader: "gilt diese voraussichtlich bis", "gilt bis", etc.
    'gilt bis',
    'gilt diese',
  ];

  /// Regex for expiry lines where "gilt" and "bis" are separated by extra words.
  /// Matches: "gilt [optional words] bis DD.MM.YYYY"
  static final _expiryGiltRegex = RegExp(
    r'\bgilt\b.*?\bbis\b.*?\b\d{2}\.\d{2}\.\d{4}\b',
    caseSensitive: false,
  );

  // ── Collection date ───────────────────────────────────────────────────────
  static const _collectionKeywords = [
    'abholbereit ab',
    'zur abholung bereit',
    'abholung ist ab',
    'verfügbar ab',
    'ausgabe ab',
    'abholung',
  ];

  static const Map<String, int> _monthMap = {
    'januar': 1,
    'februar': 2,
    'märz': 3,
    'april': 4,
    'mai': 5,
    'juni': 6,
    'juli': 7,
    'august': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'dezember': 12,
  };

  static RegExpMatch? _findDate(String line) {
    return _dateRegex.firstMatch(line) ?? _dateRegexGerman.firstMatch(line);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SCANNING HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  static final _dateRegex = RegExp(r'\b(\d{2})[\.\/-](\d{2})[\.\/-](\d{4})\b');
  static final _dateRegexGerman = RegExp(r'\b(\d{1,2})\.\s*(Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)\s+(\d{4})\b', caseSensitive: false);
  static final _timeRegex = RegExp(r'\bum\s+(\d{2}:\d{2})\s+Uhr\b');
  static final _periodRegex = RegExp(
    r'\bvom\b.*?\b\d{2}[\.\/-]\d{2}[\.\/-]\d{4}\b.*?\bbis\b',
    caseSensitive: false,
  );

  /// Returns true if [line] should be ignored entirely.
  static bool _isIgnored(String line) {
    for (final pat in _ignoreLinePatterns) {
      if (RegExp(pat, caseSensitive: false).hasMatch(line)) {
        return true;
      }
    }
    // "vom X bis Y" period line – ignore unless it contains specific words
    if (_periodRegex.hasMatch(line)) {
      final l = line.toLowerCase();

      final hasAllowKeyword =
          l.contains('gültig') ||
          l.contains('gültigkeit') ||
          l.contains('erteilt') ||
          l.contains('verlängerung');

      if (!hasAllowKeyword) return true;
    }
    return false;
  }

  /// Scans [lines] for any of [keywords] and extracts the first matching date
  /// that has not already been captured (tracked via [seen]).
  /// Looks on the trigger line first, then the next line (date sometimes wraps).
  static DeadlineResult? _scanLines(
    List<String> lines,
    List<String> keywords,
    DeadlineType type, {
    Set<String>? seen,
  }) {
    for (final kw in keywords) {
      for (int i = 0; i < lines.length; i++) {
        if (_isIgnored(lines[i])) continue;
        if (!lines[i].toLowerCase().contains(kw)) continue;

        // Same line and up to 4 lines after
        RegExpMatch? m;
        for (var offset = 0; offset <= 4; offset++) {
          final idx = i + offset;
          if (idx >= lines.length) break;
          if (_isIgnored(lines[idx])) continue;

          m = _findDate(lines[idx]);
          if (m != null && !(seen?.contains(m.group(0)!) ?? false)) {
            return DeadlineResult(
              date: _parse(m.group(0)!),
              rawValue: m.group(0)!,
              type: type,
            );
          }
        }
      }
    }
    return null;
  }

  /// Appointment scanner – same as [_scanLines] but also extracts time.
  static DeadlineResult? _scanAppointment(
    List<String> lines, {
    Set<String>? seen,
  }) {
    for (final kw in _appointmentKeywords) {
      for (int i = 0; i < lines.length; i++) {
        if (_isIgnored(lines[i])) continue;
        if (!lines[i].toLowerCase().contains(kw)) continue;

        for (var offset = 0; offset <= 4; offset++) {
          final idx = i + offset;
          if (idx >= lines.length) break;
          final checkLine = lines[idx];
          // if (_isIgnored(checkLine)) continue;
          final dm = _findDate(checkLine);
          if (dm == null) continue;
          if (seen?.contains(dm.group(0)!) ?? false) continue;

          // Extract time from same line or up to 4 lines after
          String? time;
          final tm = _timeRegex.firstMatch(checkLine);
          if (tm != null) {
            time = tm.group(1);
          } else {
            for (var tOffset = 1; tOffset <= 4; tOffset++) {
              final timeIdx = i + tOffset;
              if (timeIdx >= lines.length) break;
              final tm2 = _timeRegex.firstMatch(lines[timeIdx]);
              if (tm2 != null) {
                time = tm2.group(1);
                break;
              }
            }
          }

          return DeadlineResult(
            date: _parse(dm.group(0)!),
            rawValue: dm.group(0)!,
            type: DeadlineType.appointment,
            time: time,
          );
        }
      }
    }
    return null;
  }

  /// Fallback: returns the earliest non-ignored date in the document.
  static DeadlineResult? _fallback(List<String> lines) {
    final dates = <String>[];
    for (final line in lines) {
      if (_isIgnored(line)) continue;
      for (final m in [..._dateRegex.allMatches(line), ..._dateRegexGerman.allMatches(line)]) {
        dates.add(m.group(0)!);
      }
    }
    if (dates.isEmpty) return null;
    dates.sort((a, b) => _parse(a).compareTo(_parse(b)));
    final raw = dates.first;
    return DeadlineResult(
      date: _parse(raw),
      rawValue: raw,
      type: DeadlineType.deadline, // conservative fallback type
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DATE UTILITIES
  // ───────────────────────────────────────────────────────────────────────────

  static DateTime _parse(String dateStr) {
    if (dateStr.contains(RegExp(r'[a-zA-Z]'))) {
      // German format: 30. Juni 2025
      final parts = dateStr.split(RegExp(r'\s+'));
      if (parts.length != 3) throw FormatException('Invalid German date format');
      final day = int.parse(parts[0].replaceAll('.', ''));
      final monthStr = parts[1].toLowerCase();
      final year = int.parse(parts[2]);
      final month = _monthMap[monthStr];
      if (month == null) throw FormatException('Unknown month: $monthStr');
      return DateTime(year, month, day);
    } else {
      // Old format: 30.06.2025
      final separator = dateStr.contains('.')
          ? '.'
          : dateStr.contains('-')
          ? '-'
          : '/';
      final p = dateStr.split(separator);
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    }
  }

  /// Default relative deadline: today + 1 month.
  static DateTime _relativeDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, now.day);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TEXT HELPERS (unchanged)
  // ───────────────────────────────────────────────────────────────────────────

  static String _normalise(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

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

  // ───────────────────────────────────────────────────────────────────────────
  // CLASSIFICATION (unchanged)
  // ───────────────────────────────────────────────────────────────────────────

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
      final neg = _countMatches(normText, cat.negativeKeywords);
      if (neg.count > 0) continue;

      final decisive = _countMatches(normText, cat.decisiveKeywords);
      // print(
      //   'Category "${cat.labelKey}": ${decisive.count} decisive, ${neg.count} negative',
      // );
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

  // ───────────────────────────────────────────────────────────────────────────
  // TITLE EXTRACTION (unchanged)
  // ───────────────────────────────────────────────────────────────────────────

  static const _titlePatterns = [
    'Einladung zum Termin',
    'Aufforderung zur Mitwirkung',
    'Weiterbewilligungsantrag',
    'Veränderungsmitteilung',
    'Hauptantrag Bürgergeld',
    'Terminbestätigung',
    'Einladung zur persönlichen Vorsprache',
    'Aufforderung zur Vorlage von Unterlagen',
    'Nachforderung von Unterlagen',
    'Fiktionsbescheinigung',
    'Bewilligungsbescheid',
    'Ablehnungsbescheid',
    'Elektronischer Aufenthaltstitel',
    'Einkommensteuerbescheid',
    'Steuerbescheid',
    'Steuererstattung',
    'Aufforderung zur Abgabe der Steuererklärung',
    'Verspätungszuschlag',
    'Kontoauszug',
    'Überweisungsbestätigung',
    'Rücklastschrift',
    'Sicherheitswarnung',
    'Letzte Mahnung',
    'Mahnung',
    'Zahlungserinnerung',
    'Inkasso-Forderung',
    'Vollstreckungsbescheid',
    'Mahnbescheid',
    'Rechnung',
    'Kündigung Mietvertrag',
    'Fristlose Kündigung',
    'Mieterhöhung',
    'Nebenkostenabrechnung',
    'Mietvertrag',
    'Kautionsabrechnung',
    'Versicherungsschein',
    'Schadenmeldung',
    'Beitragsrechnung',
    'Kündigungsbestätigung',
    'Kündigung',
    'Arbeitsvertrag',
    'Versicherungsbescheinigung',
    'Mitgliedsbescheinigung',
    'Krankengeld',
    'Kassenwechsel',
  ];

  static String _extractTitle(String text) {
    final header = text.length > 500 ? text.substring(0, 500) : text;
    final headerLow = _normalise(header);
    for (final pattern in _titlePatterns) {
      if (headerLow.contains(_normalise(pattern))) return pattern;
    }
    final firstLine = text
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => 'Unbekanntes Dokument');
    return firstLine;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SUMMARY EXTRACTION (unchanged)
  // ───────────────────────────────────────────────────────────────────────────

  static const _boilerplate = [
    'sehr geehrte',
    'sehr geehrter',
    'mit freundlichen grüßen',
    'hochachtungsvoll',
  ];

  static String _extractSummary(String text, String? deadlineRaw) {
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

    if (deadlineRaw != null &&
        deadlineRaw != 'RELATIVE' &&
        !summary.contains(deadlineRaw)) {
      summary += ' Frist/Datum: $deadlineRaw.';
    }

    if (summary.isEmpty) {
      summary = text.substring(0, text.length.clamp(0, 200)).trim();
    }

    return summary;
  }
}

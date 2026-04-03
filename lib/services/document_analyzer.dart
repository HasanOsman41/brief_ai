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
import 'package:fuzzywuzzy/fuzzywuzzy.dart' show partialRatio;

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
        summaryKey: 'summary_unknown_document',
        deadline: null,
        nextStepKeys: [],
        confidence: AnalysisConfidence.unknown,
        matchedKeywords: [],
      );
    }

    // 1. Classify
    final classResult = _classify(ocrText);

    // 2. Extract deadline (structured)
    final deadlineResult = extractDeadlineInfo(ocrText);

    // 3. Extract summary key (always provided)
    final summaryKey = _extractSummaryKey(classResult.category);

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
      summaryKey: summaryKey,
      deadline: deadlineResult?.rawValue == 'RELATIVE'
          ? null
          : deadlineResult?.date.toString(),
      nextStepKeys: nextStepKeys,
      confidence: classResult.confidence,
      matchedKeywords: classResult.matchedKeywords,
      trustScore: classResult.trustScore,
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
  static final _dateRegexGerman = RegExp(
    r'\b(\d{1,2})\.\s*(Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)\s+(\d{4})\b',
    caseSensitive: false,
  );
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
        // if (_isIgnored(lines[i])) continue;
        if (!lines[i].toLowerCase().contains(kw)) continue;
        // Same line and up to 4 lines after
        RegExpMatch? m;
        for (var offset = 0; offset <= 4; offset++) {
          final idx = i + offset;
          if (idx >= lines.length) break;
          if (_isIgnored(lines[idx])) continue;

          m = _findDate(lines[idx]);
          if (m != null && !(seen?.contains(m.group(0)!) ?? false)) {
            print(
              'found date "${m.group(0)!}" for trigger "$kw" in line: ${lines[idx]}',
            );
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
      for (final m in [
        ..._dateRegex.allMatches(line),
        ..._dateRegexGerman.allMatches(line),
      ]) {
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
      if (parts.length != 3)
        throw FormatException('Invalid German date format');
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

  // ─────────────────────────────────────────────────────────────────────────
  // Fuzzy match threshold tuning
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum score for a keyword to count as "matched".
  /// 85 tolerates 1-2 OCR character errors in short words,
  /// 3-4 errors in longer phrases.
  static const int _kThresholdDecisive = 85;
  static const int _kThresholdSupporting = 80;
  static const int _kThresholdHeader = 88; // stricter – header is short zone

  /// Strong negatives must still be fairly precise to avoid false suppression.
  static const int _kThresholdNegative = 82;

  // ─────────────────────────────────────────────────────────────────────────
  // Fuzzy _countMatches  (replaces the old contains() version)
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns how many [keywords] fuzzy-match inside [normText],
  /// along with the matched keyword strings and their best scores.
  ///
  /// Uses partialRatio so a keyword like "widerspruch" still matches even if
  /// OCR produced "wlderspruch" or "w1derspruch".
  static ({int count, List<String> matched, List<int> scores})
  _fuzzyCountMatches(
    String normText,
    List<String> keywords, {
    required int threshold,
  }) {
    final matched = <String>[];
    final scores = <int>[];

    for (final kw in keywords) {
      final normKw = _normalise(kw);
      // partialRatio slides the shorter string over the longer one and
      // returns the best window score → ideal for keyword-in-document search.
      final score = normText.contains(normKw)?100:0;//partialRatio(normKw, normText);
      if (score >= threshold) {
        matched.add(kw);
        scores.add(score);
      }
    }

    return (count: matched.length, matched: matched, scores: scores);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _classify
  // ─────────────────────────────────────────────────────────────────────────

  static ({
    CategoryDefinition? category,
    AnalysisConfidence confidence,
    List<String> matchedKeywords,
    int trustScore,
  })
  _classify(String ocrText) {
    // ── 1. Prepare text zones ────────────────────────────────────────────────
    final normText = _normalise(ocrText);

    final lines = ocrText.split('\n');
    final headerLines = lines.take(10).join(' ');
    // final headerSlice = ocrText.length > 800
    //     ? ocrText.substring(0, 800)
    //     : ocrText;`
    final normHeader = _normalise('$headerLines $headerLines');

    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                  _classify() – START                        ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ Total chars     : ${ocrText.length}');
    print('║ Normalised chars: ${normText.length}');
    print('║ Header chars    : ${normHeader.length}');
    print('║ Total lines     : ${lines.length}');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');
    print('── normText (first 300 chars) ──────────────────────────────────');
    print(normText.substring(0, normText.length.clamp(0, 300)));
    print('── normHeader (first 200 chars) ────────────────────────────────');
    print(normHeader.substring(0, normHeader.length.clamp(0, 200)));
    print('');

    // ── 2. Per-category scoring ──────────────────────────────────────────────
    int bestScore = -999999;
    CategoryDefinition? bestCat;
    List<String> bestMatched = [];

    int bestHeaderCount = 0;
    int bestDecisiveCount = 0;
    int bestSupportingCount = 0;
    int bestWeakNegativeCount = 0;
    int bestCumulativeScore = 0;

    print(
      '── Per-category scan (${BriefAiCategories.all.length} categories) ──────────────────────',
    );
    print('');

    for (final cat in BriefAiCategories.all) {
      print('┌─ [${cat.id}] "${cat.labelKey}" ─────────────────────────────');

      // ── 2a. Strong negatives veto ──────────────────────────────────────────
      final strongNeg = _fuzzyCountMatches(
        normText,
        cat.strongNegativeKeywords,
        threshold: _kThresholdNegative,
      );
      if (strongNeg.count > 0) {
        print('│  ✗ VETOED by strong negative(s): ${strongNeg.matched}');
        print('└─────────────────────────────────────────────────────────────');
        print('');
        continue;
      }
      if (cat.strongNegativeKeywords.isNotEmpty) {
        print(
          '│  strong negatives checked: ${cat.strongNegativeKeywords.length} → none matched (threshold: $_kThresholdNegative)',
        );
      }

      // ── 2b. Fuzzy match every group ────────────────────────────────────────
      final header = _fuzzyCountMatches(
        normHeader,
        cat.headerKeywords,
        threshold: _kThresholdHeader,
      );
      final decisive = _fuzzyCountMatches(
        normText,
        cat.decisiveKeywords,
        threshold: _kThresholdDecisive,
      );
      final supporting = _fuzzyCountMatches(
        normText,
        cat.supportingKeywords,
        threshold: _kThresholdSupporting,
      );
      final weakNeg = _fuzzyCountMatches(
        normText,
        cat.weakNegativeKeywords,
        threshold: _kThresholdNegative,
      );

      print(
        '│  header      [thresh: $_kThresholdHeader] → ${header.count}/${cat.headerKeywords.length} matched',
      );
      if (header.matched.isNotEmpty) {
        for (int i = 0; i < header.matched.length; i++) {
          print('│    ✓ "${header.matched[i]}"  score: ${header.scores[i]}');
        }
      }

      print(
        '│  decisive    [thresh: $_kThresholdDecisive] → ${decisive.count}/${cat.decisiveKeywords.length} matched',
      );
      if (decisive.matched.isNotEmpty) {
        for (int i = 0; i < decisive.matched.length; i++) {
          print(
            '│    ✓ "${decisive.matched[i]}"  score: ${decisive.scores[i]}',
          );
        }
      }

      print(
        '│  supporting  [thresh: $_kThresholdSupporting] → ${supporting.count}/${cat.supportingKeywords.length} matched',
      );
      if (supporting.matched.isNotEmpty) {
        for (int i = 0; i < supporting.matched.length; i++) {
          print(
            '│    ✓ "${supporting.matched[i]}"  score: ${supporting.scores[i]}',
          );
        }
      }

      print(
        '│  weak neg    [thresh: $_kThresholdNegative] → ${weakNeg.count}/${cat.weakNegativeKeywords.length} matched',
      );
      if (weakNeg.matched.isNotEmpty) {
        for (int i = 0; i < weakNeg.matched.length; i++) {
          print('│    ⚠ "${weakNeg.matched[i]}"  score: ${weakNeg.scores[i]}');
        }
      }

      // ── 2c. Minimum signal gate ────────────────────────────────────────────
      final hasMinimumSignal =
          header.count > 0 || decisive.count > 0 || supporting.count >= 2;

      if (!hasMinimumSignal) {
        print(
          '│  ✗ SKIPPED – minimum signal not met '
          '(header:${header.count}, decisive:${decisive.count}, supporting:${supporting.count})',
        );
        print('└─────────────────────────────────────────────────────────────');
        print('');
        continue;
      }

      // ── 2d. Weighted integer score ─────────────────────────────────────────
      final score =
          (header.count * 150) +
          (decisive.count * 100) +
          (supporting.count * 20) -
          (weakNeg.count * 35);

      final cumulativeScore = [
        ...header.scores,
        ...decisive.scores,
        ...supporting.scores,
      ].fold(0, (a, b) => a + b);

      print(
        '│  score = '
        '(${header.count}×150) + (${decisive.count}×100) + '
        '(${supporting.count}×20) - (${weakNeg.count}×35) = $score',
      );
      print('│  cumulative fuzzy score: $cumulativeScore');

      // ── 2e. Best-candidate selection ───────────────────────────────────────
      final isBetter =
          score > bestScore ||
          (score == bestScore && header.count > bestHeaderCount) ||
          (score == bestScore &&
              header.count == bestHeaderCount &&
              decisive.count > bestDecisiveCount) ||
          (score == bestScore &&
              header.count == bestHeaderCount &&
              decisive.count == bestDecisiveCount &&
              supporting.count > bestSupportingCount) ||
          (score == bestScore &&
              header.count == bestHeaderCount &&
              decisive.count == bestDecisiveCount &&
              supporting.count == bestSupportingCount &&
              weakNeg.count < bestWeakNegativeCount) ||
          (score == bestScore &&
              header.count == bestHeaderCount &&
              decisive.count == bestDecisiveCount &&
              supporting.count == bestSupportingCount &&
              weakNeg.count == bestWeakNegativeCount &&
              cumulativeScore > bestCumulativeScore);

      if (isBetter) {
        final prevLabel = bestCat?.labelKey ?? 'none';
        print('│  ★ NEW BEST  (was: "$prevLabel" @ $bestScore → now: $score)');
        bestScore = score;
        bestCat = cat;
        bestMatched = [
          ...header.matched,
          ...decisive.matched,
          ...supporting.matched,
        ];
        bestHeaderCount = header.count;
        bestDecisiveCount = decisive.count;
        bestSupportingCount = supporting.count;
        bestWeakNegativeCount = weakNeg.count;
        bestCumulativeScore = cumulativeScore;
      } else {
        print(
          '│  ✗ not better than current best "${bestCat?.labelKey}" @ $bestScore',
        );
      }

      print('└─────────────────────────────────────────────────────────────');
      print('');
    }

    // ── 3. Reject zero / no result ────────────────────────────────────────────
    print('── Scan complete ────────────────────────────────────────────────');
    if (bestCat == null || bestScore <= 0) {
      print('✗ No valid category found (bestScore: $bestScore)');
      print('  → returning AnalysisConfidence.unknown');
      print(
        '═════════════════════════════════════════════════════════════════',
      );
      return (
        category: null,
        confidence: AnalysisConfidence.unknown,
        matchedKeywords: <String>[],
        trustScore: 0,
      );
    }

    // ── 4. Confidence ─────────────────────────────────────────────────────────
    final confidence =
        (bestHeaderCount >= 1 && bestDecisiveCount >= 1) ||
            (bestHeaderCount >= 1 && bestSupportingCount >= 2) ||
            (bestDecisiveCount >= 2) ||
            (bestDecisiveCount >= 1 && bestSupportingCount >= 2)
        ? AnalysisConfidence.high
        : (bestHeaderCount >= 1) ||
              (bestDecisiveCount >= 1) ||
              (bestSupportingCount >= 3)
        ? AnalysisConfidence.medium
        : AnalysisConfidence.low;

    final confidenceReason = () {
      if (bestHeaderCount >= 1 && bestDecisiveCount >= 1)
        return 'header≥1 + decisive≥1';
      if (bestHeaderCount >= 1 && bestSupportingCount >= 2)
        return 'header≥1 + supporting≥2';
      if (bestDecisiveCount >= 2) return 'decisive≥2';
      if (bestDecisiveCount >= 1 && bestSupportingCount >= 2)
        return 'decisive≥1 + supporting≥2';
      if (bestHeaderCount >= 1) return 'header≥1 only';
      if (bestDecisiveCount >= 1) return 'decisive≥1 only';
      if (bestSupportingCount >= 3) return 'supporting≥3 only';
      return 'fallback low';
    }();

    // ── 5. Trust score ────────────────────────────────────────────────────────
    const maxScore = 700;
    final trustScore = (bestScore / maxScore * 100).clamp(0, 100).round();

    // ── Final summary ─────────────────────────────────────────────────────────
    print('');
    print('ocr lines: ${lines.asMap().entries.map((e) => '[${e.key}] ${e.value}').join('\n')}');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                  _classify() – RESULT                       ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ category      : ${bestCat.id} / "${bestCat.labelKey}"');
    print('║ score         : $bestScore  (max: $maxScore)');
    print('║ trust score   : $trustScore / 100');
    print('║ confidence    : $confidence  ← $confidenceReason');
    print('║ header hits   : $bestHeaderCount');
    print('║ decisive hits : $bestDecisiveCount');
    print('║ supporting    : $bestSupportingCount');
    print('║ weak neg hits : $bestWeakNegativeCount');
    print('║ cumulative fz : $bestCumulativeScore');
    print('║ matched kws   : ${bestMatched.length}');
    for (final kw in bestMatched) {
      print('║   • "$kw"');
    }
    print('╚══════════════════════════════════════════════════════════════╝');

    return (
      category: bestCat,
      confidence: confidence,
      matchedKeywords: bestMatched,
      trustScore: trustScore,
    );
  }
  // ───────────────────────────────────────────────────────────────────────────
  // SUMMARY EXTRACTION
  // ───────────────────────────────────────────────────────────────────────────

  static String _extractSummaryKey(CategoryDefinition? category) {
    return category?.summaryKey ?? 'summary_unknown_document';
  }
}

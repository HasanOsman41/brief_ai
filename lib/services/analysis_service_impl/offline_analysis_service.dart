/// BriefAI Offline Analysis Service
///
/// Implements local document analysis using keyword matching and pattern recognition.
/// This service provides fast, privacy-focused document classification without
/// requiring internet connectivity.
///
/// Features:
/// - Local keyword-based document classification
/// - Advanced deadline extraction with multiple date formats
/// - German administrative document specialization
/// - Confidence scoring and trust metrics
/// - No external dependencies or API calls
library;

import 'package:brief_ai/models/category_definition.dart';
import '../../models/document_result.dart';
import '../analysis_service.dart';
import 'package:brief_ai/data/brief_ai_categories.dart';
import '../ocr_service.dart';

/// Offline analysis service using local keyword matching and pattern recognition.
///
/// Provides immediate document analysis without network requirements.
/// Optimized for German administrative documents and common bureaucratic forms.
class OfflineAnalysisService implements AnalysisService {
  /// Analyzes document images using OCR and local document analyzer.
  ///
  /// Performs comprehensive document classification including:
  /// - OCR text extraction from images
  /// - Category detection based on keyword matching
  /// - Deadline extraction with priority handling
  /// - Confidence assessment based on match quality
  @override
  Future<DocumentResult> analyze(
    List<String> imagePaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    // Perform OCR on all images
    final ocrText = await OcrService.instance.recogniseAll(
      imagePaths,
      onProgress: onProgress,
    );

    // Analyze the extracted text
    final result = DocumentAnalyzer.analyze(ocrText);

    return DocumentResult(
      category: result.category,
      title: result.title,
      summaryKey: result.summaryKey,
      deadline: result.deadline,
      nextStepKeys: result.nextStepKeys,
      confidence: result.confidence,
      matchedKeywords: result.matchedKeywords,
      trustScore: result.trustScore,
      ocrText: ocrText,
    );
  }

  /// Always returns true as offline analysis has no external dependencies.
  @override
  bool get isAvailable => true;

  /// Returns the display name for this analysis service.
  @override
  String get serviceName => 'Offline Analysis';
}

// ═══════════════════════════════════════════════════════════════════════════════
// DocumentAnalyzer - Core Analysis Engine
// ═══════════════════════════════════════════════════════════════════════════════

/// Core document analysis engine for BriefAI.
///
/// Provides comprehensive document classification and deadline extraction
/// using keyword matching, pattern recognition, and fuzzy text matching.
///
/// Usage:
/// ```dart
/// final result = DocumentAnalyzer.analyze(ocrText);
/// ```
///
/// The returned [DocumentResult] contains:
/// - `category`: Document classification with main category and sub-category
/// - `title`: Extracted or derived document title
/// - `summaryKey`: Localization key for document summary
/// - `deadline`: Most important extracted date (dd.MM.yyyy format)
/// - `nextStepKeys`: Ordered action items as localization keys
/// - `confidence`: Analysis confidence level (high/medium/low/unknown)
/// - `matchedKeywords`: Keywords that triggered the classification
/// - `trustScore`: Numerical confidence score (0-100)

// ─────────────────────────────────────────────────────────────────────────────
// DeadlineResult - Structured Date Information
// ─────────────────────────────────────────────────────────────────────────────

/// Categorizes different types of dates found in documents.
///
/// Used to prioritize deadlines by importance and determine appropriate
/// user actions and notifications.
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

/// Structured result containing extracted deadline information.
///
/// Returned by [DocumentAnalyzer.extractDeadlineInfo] with parsed date,
/// original text, semantic type, and optional time information.
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
// DocumentAnalyzer - Main Analysis Class
// ─────────────────────────────────────────────────────────────────────────────

/// Core document analysis engine providing classification and deadline extraction.
///
/// This class contains all the logic for analyzing German administrative documents,
/// extracting deadlines, and classifying document types using keyword matching.
class DocumentAnalyzer {
  DocumentAnalyzer._();

  // ───────────────────────────────────────────────────────────────────────────
  // Public Analysis API
  // ───────────────────────────────────────────────────────────────────────────

  /// Analyzes OCR text and returns comprehensive document information.
  ///
  /// Performs multi-phase analysis:
  /// 1. Document classification (main category → sub-category)
  /// 2. Deadline extraction with priority handling
  /// 3. Summary key generation
  /// 4. Next steps determination
  ///
  /// Returns [DocumentResult] with unknown confidence for empty input.
  static DocumentResult analyze(String ocrText) {
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

    // 1. Classify (two-phase: main category → sub-category)
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
  // Public Deadline Extraction API
  // ───────────────────────────────────────────────────────────────────────────

  /// Extracts the most important deadline from document text.
  ///
  /// Applies priority ranking:
  /// legalDeadline > deadline > paymentDeadline > appointment > expiryDate > collectionDate
  ///
  /// Returns null if no actionable dates are found.
  static DeadlineResult? extractDeadlineInfo(String text) {
    final all = extractAllDeadlines(text);
    return all.isEmpty ? null : all.first;
  }

  /// Extracts all actionable dates from document text.
  ///
  /// Returns comprehensive list of deadlines sorted by priority (highest first).
  /// Handles multiple date formats including German month names and relative dates.
  static List<DeadlineResult> extractAllDeadlines(String text) {
    final lines = text.split('\n');
    final results = <DeadlineResult>[];
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
        break;
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

    results.sort((a, b) => a.type.index.compareTo(b.type.index));
    return results;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KEYWORD TABLES
  // ───────────────────────────────────────────────────────────────────────────

  static const _ignoreLinePatterns = [
    r',\s*den\s+\d{2}\.\d{2}\.\d{4}',
    r'^\s*Datum\s*:',
    r'\berstellt\s+am\b',
    r'\bausgestellt\s+am\b',
    r'\bAntrag\s+vom\b',
    r'\bIhr\s+Antrag\s+vom\b',
    r'\bgestellt\s+am\b',
    r'\beingereicht\s+am\b',
    r'\bOnline-Antrag\s+vom\b',
    r'\bGeburtsdatum\b',
    r'\bgeboren\s+am\b',
    r'\bSchreiben\s+vom\b',
    r'\bmit\s+Schreiben\s+vom\b',
    r'\bzuletzt\s+am\b',
    r'\bbereits\s+am\b',
    r'\bwurden\s+Sie\s+aufgefordert\b',
    r'\bmitgeteilt\s+am\b',
    r'\bim\s+Zeitraum\b',
    r'\bzwischen\b',
  ];

  static const _relativeKeywords = [
    'innerhalb eines monats',
    'innerhalb von zwei wochen',
    'rechtsbehelfsbelehrung',
  ];

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
    'für den',
    'ist für den',
    'vorgesehen',
    'termin',
    'termindaten',
    'einladung',
    'uhr',
  ];

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
    'gilt bis',
    'gilt diese',
  ];

  static final _expiryGiltRegex = RegExp(
    r'\bgilt\b.*?\bbis\b.*?\b\d{2}\.\d{2}\.\d{4}\b',
    caseSensitive: false,
  );

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

  static bool _isIgnored(String line) {
    for (final pat in _ignoreLinePatterns) {
      if (RegExp(pat, caseSensitive: false).hasMatch(line)) return true;
    }
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

  static DeadlineResult? _scanLines(
    List<String> lines,
    List<String> keywords,
    DeadlineType type, {
    Set<String>? seen,
  }) {
    for (final kw in keywords) {
      for (int i = 0; i < lines.length; i++) {
        if (!lines[i].toLowerCase().contains(kw)) continue;
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
          final dm = _findDate(checkLine);
          if (dm == null) continue;
          if (seen?.contains(dm.group(0)!) ?? false) continue;
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
      type: DeadlineType.deadline,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DATE UTILITIES
  // ───────────────────────────────────────────────────────────────────────────

  static DateTime _parse(String dateStr) {
    if (dateStr.contains(RegExp(r'[a-zA-Z]'))) {
      final parts = dateStr.split(RegExp(r'\s+'));
      if (parts.length != 3) {
        throw FormatException('Invalid German date format');
      }
      final day = int.parse(parts[0].replaceAll('.', ''));
      final monthStr = parts[1].toLowerCase();
      final year = int.parse(parts[2]);
      final month = _monthMap[monthStr];
      if (month == null) throw FormatException('Unknown month: $monthStr');
      return DateTime(year, month, day);
    } else {
      final separator = dateStr.contains('.')
          ? '.'
          : dateStr.contains('-')
          ? '-'
          : '/';
      final p = dateStr.split(separator);
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    }
  }

  static DateTime _relativeDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, now.day);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TEXT HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  static String _normalise(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  // ─────────────────────────────────────────────────────────────────────────
  // Fuzzy match thresholds
  // ─────────────────────────────────────────────────────────────────────────

  static const int _kThresholdDecisive = 85;
  static const int _kThresholdSupporting = 80;
  static const int _kThresholdHeader = 88;
  static const int _kThresholdNegative = 82;

  /// Threshold for main-category keyword matching.
  /// Slightly looser than header to handle OCR noise on institution names.
  static const int _kThresholdMainCat = 80;

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
      final score = normText.contains(normKw) ? 100 : 0;
      // final score = partialRatio(normKw, normText); // swap in for full fuzzy
      if (score >= threshold) {
        matched.add(kw);
        scores.add(score);
      }
    }

    return (count: matched.length, matched: matched, scores: scores);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHASE 1 – Detect main category from mainGroups keywords
  // ─────────────────────────────────────────────────────────────────────────

  /// Scores every [MainCategoryDefinition] against [normText] and returns a list of
  /// best-matching [MainCategory] values (handles ties). Returns empty list when
  /// nothing scores above zero.
  ///
  /// The `categoryOther` group has an empty keyword list and therefore always
  /// scores 0 – it is used only as a fallback after sub-category scan fails.
  static List<MainCategory> _detectMainCategories(String normText) {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║           PHASE 1 – Main-category detection                  ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    int bestScore = 0;
    final bestMains = <MainCategory>[];

    for (final group in BriefAiCategories.mainGroups) {
      if (group.keywords.isEmpty) continue; // skip categoryOther

      final result = _fuzzyCountMatches(
        normText,
        group.keywords,
        threshold: _kThresholdMainCat,
      );

      print(
        '  [${group.value}]  hits: ${result.count}/${group.keywords.length}'
        '  matched: ${result.matched}',
      );

      if (result.count > bestScore) {
        bestScore = result.count;
        bestMains.clear();
        bestMains.add(group.value);
      } else if (result.count == bestScore && result.count > 0) {
        // Tie: add to the list of best candidates
        bestMains.add(group.value);
      }
    }

    if (bestMains.isEmpty || bestScore == 0) {
      print('  → No main category detected – will scan ALL sub-categories.');
    } else if (bestMains.length == 1) {
      print('  → Best main category: ${bestMains.first}  (score: $bestScore)');
    } else {
      print(
        '  → TIE: ${bestMains.length} main categories with score $bestScore: '
        '${bestMains.join(', ')}',
      );
    }
    print('');

    return bestMains;
  }
  // ─────────────────────────────────────────────────────────────────────────
  // PHASE 2 – Sub-category scoring (unchanged logic, scoped to a group)
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
    final headerLines = lines.take(15).join(' ');
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

    // ── 2. PHASE 1 – detect main category/categories ───────────────────────────
    final detectedMains = _detectMainCategories(normText);

    if (detectedMains.isEmpty) {
      return (
        category: null,
        confidence: AnalysisConfidence.unknown,
        matchedKeywords: <String>[],
        trustScore: 0,
      );
    }

    // ── 3. Select candidate sub-categories ──────────────────────────────────
    //
    // If one or more main categories were detected, restrict the search to those groups.
    // If detection was inconclusive (empty list), fall back to scanning everything.
    final candidates = detectedMains.isEmpty
        ? BriefAiCategories.all
        : BriefAiCategories.all
              .where((c) => detectedMains.contains(c.mainCategory))
              .toList();

    print('── PHASE 2 – Sub-category scan ─────────────────────────────────');
    print(
      '   Scanning ${candidates.length} candidate(s) '
      'in [${detectedMains.join(', ')}]',
    );
    print('');

    // ── 4. Per-category scoring ──────────────────────────────────────────────
    int bestScore = -999999;
    CategoryDefinition? bestCat;
    List<String> bestMatched = [];

    int bestHeaderCount = 0;
    int bestDecisiveCount = 0;
    int bestSupportingCount = 0;
    int bestWeakNegativeCount = 0;
    int bestCumulativeScore = 0;

    for (final cat in candidates) {
      print('┌─ [${cat.id}] "${cat.labelKey}" ─────────────────────────────');

      // ── 4a. Strong negatives veto ──────────────────────────────────────────
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
          '│  strong negatives checked: ${cat.strongNegativeKeywords.length}'
          ' → none matched (threshold: $_kThresholdNegative)',
        );
      }

      // ── 4b. Fuzzy match every group ────────────────────────────────────────
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

      // ── 4c. Minimum signal gate ────────────────────────────────────────────
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

      // ── 4d. Weighted integer score ─────────────────────────────────────────
      final score =
          (header.count * 200) +
          (decisive.count * 100) +
          (supporting.count * 20) -
          (weakNeg.count * 35);

      final cumulativeScore = [
        ...header.scores,
        ...decisive.scores,
        ...supporting.scores,
      ].fold(0, (a, b) => a + b);

      print(
        '│  score = (${header.count}×200) + (${decisive.count}×100) + '
        '(${supporting.count}×20) - (${weakNeg.count}×35) = $score',
      );
      print('│  cumulative fuzzy score: $cumulativeScore');

      // ── 4e. Best-candidate selection ───────────────────────────────────────
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

    // ── 5. Reject zero / no result ────────────────────────────────────────────
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

    // ── 6. Confidence ─────────────────────────────────────────────────────────
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
      if (bestHeaderCount >= 1 && bestDecisiveCount >= 1) {
        return 'header≥1 + decisive≥1';
      }
      if (bestHeaderCount >= 1 && bestSupportingCount >= 2) {
        return 'header≥1 + supporting≥2';
      }
      if (bestDecisiveCount >= 2) return 'decisive≥2';
      if (bestDecisiveCount >= 1 && bestSupportingCount >= 2) {
        return 'decisive≥1 + supporting≥2';
      }
      if (bestHeaderCount >= 1) return 'header≥1 only';
      if (bestDecisiveCount >= 1) return 'decisive≥1 only';
      if (bestSupportingCount >= 3) return 'supporting≥3 only';
      return 'fallback low';
    }();

    // ── 7. Trust score ────────────────────────────────────────────────────────
    const maxScore = 700;
    final trustScore = (bestScore / maxScore * 100).clamp(0, 100).round();

    // ── Final summary ─────────────────────────────────────────────────────────
    print('');
    print(
      'ocr lines: ${lines.asMap().entries.map((e) => '[${e.key}] ${e.value}').join('\n')}',
    );
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                  _classify() – RESULT                       ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ main category : $detectedMains');
    print('║ sub-category  : ${bestCat.id} / "${bestCat.labelKey}"');
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

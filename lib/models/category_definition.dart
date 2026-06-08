/// BriefAI – Category Definition Models
library;

import 'package:brief_ai/utils/risk_level.dart';

import 'document_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main-category group
// ─────────────────────────────────────────────────────────────────────────────

class MainCategoryDefinition {
  final MainCategory value;

  /// l10n key → look up in AppLocalizations
  final String labelKey;

  /// Keywords that strongly indicate this main category.
  /// A match gives every sub-category of this group a +500 head-start.
  final List<String> keywords;

  const MainCategoryDefinition({
    required this.value,
    required this.labelKey,
    this.keywords = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-category (one leaf classification with all its keywords & step keys)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryDefinition {
  final String id;

  /// l10n key for the category name → 'cat_<id>_label'
  final String labelKey;

  /// l10n key for fixed summary → 'cat_<id>_summary' (null if no fixed summary)
  final String? summaryKey;

  /// The main group this sub-category belongs to.
  final MainCategory mainCategory;

  /// Matched against the document header / title area.
  /// A single match here strongly boosts classification confidence.
  final List<String> headerKeywords;

  /// A single decisive keyword match is enough to classify
  final List<String> decisiveKeywords;

  /// Need 2+ supporting matches when no decisive keyword found
  final List<String> supportingKeywords;

  /// If ANY strong negative keyword is present, this category is
  /// immediately disqualified regardless of other matches.
  final List<String> strongNegativeKeywords;

  /// Reduces confidence score when present, but does not outright disqualify.
  final List<String> weakNegativeKeywords;

  /// Ordered l10n keys for next steps → 'cat_<id>_step1', 'cat_<id>_step2', …
  final List<String> nextStepKeys;


  const CategoryDefinition({
    required this.id,
    required this.labelKey,
    this.summaryKey,
    required this.mainCategory,
    this.headerKeywords = const [],
    required this.decisiveKeywords,
    required this.supportingKeywords,
    this.strongNegativeKeywords = const [],
    this.weakNegativeKeywords = const [],
    required this.nextStepKeys,
  });
}

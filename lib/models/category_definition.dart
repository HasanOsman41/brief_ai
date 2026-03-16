/// BriefAI – Category Definition Models

import 'document_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main-category group
// ─────────────────────────────────────────────────────────────────────────────

class MainCategoryDefinition {
  final MainCategory value;

  /// l10n key → look up in AppLocalizations (e.g. AppLocalizations.of(ctx).cat_categoryJobcenter_label)
  final String labelKey;

  const MainCategoryDefinition({required this.value, required this.labelKey});
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-category (one leaf classification with all its keywords & step keys)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryDefinition {
  final String id;

  /// l10n key for the category name → 'cat_<id>_label'
  final String labelKey;

  /// The main group this sub-category belongs to.
  final MainCategory mainCategory;

  /// A single decisive keyword match is enough to classify
  final List<String> decisiveKeywords;

  /// Need 2+ supporting matches when no decisive keyword found
  final List<String> supportingKeywords;

  /// If ANY negative keyword is present, this category is disqualified
  final List<String> negativeKeywords;

  /// Ordered l10n keys for next steps → 'cat_<id>_step1', 'cat_<id>_step2', …
  final List<String> nextStepKeys;

  final RiskLevel riskLevel;

  const CategoryDefinition({
    required this.id,
    required this.labelKey,
    required this.mainCategory,
    required this.decisiveKeywords,
    required this.supportingKeywords,
    required this.negativeKeywords,
    required this.nextStepKeys,
    required this.riskLevel,
  });
}

/// BriefAI – Document Analysis Result Model

import 'package:flutter/material.dart';

enum MainCategory {
  categoryJobcenter('categoryJobcenter', Icons.business_center),
  categoryAuslaenderbehoerde(
    'categoryAuslaenderbehoerde',
    Icons.account_balance,
  ),
  categoryKrankenkasse('categoryKrankenkasse', Icons.local_hospital),
  categoryFinanzamt('categoryFinanzamt', Icons.attach_money),
  categoryContracts('categoryContracts', Icons.description),
  categoryBills('categoryBills', Icons.receipt),
  categoryBank('categoryBank', Icons.account_balance),
  categoryInsurance('categoryInsurance', Icons.security),
  categoryRent('categoryRent', Icons.home),
  categoryOther('categoryOther', Icons.insert_drive_file);

  const MainCategory(this.key, this.iconData);

  /// The localization key — used to look up the translated label.
  final String key;

  /// Icon data for the category
  final IconData iconData;

  /// Convenience alias to keep existing code working.
  IconData get icon => iconData;

  /// Returns the MainCategory whose key matches [key],
  /// or null if no match is found.
  static MainCategory? fromKey(String key) {
    try {
      return MainCategory.values.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Helper method to get an Icon widget with default size
  Icon getIcon({double size = 24.0, Color? color}) {
    return Icon(iconData, size: size, color: color);
  }
}

enum AnalysisConfidence { high, medium, low, unknown }

class DocumentCategory {
  final String id;

  /// l10n key → resolve via AppLocalizations: 'cat_<id>_label'
  final String labelKey;

  /// Top-level group this category belongs to.
  final MainCategory mainCategory;

  const DocumentCategory({
    required this.id,
    required this.labelKey,
    required this.mainCategory,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label_key': labelKey,
    'main_category': mainCategory.name,
  };
}

class DocumentResult {
  /// Matched category (null if document could not be classified)
  final DocumentCategory? category;

  /// Extracted or derived document title
  final String title;

  /// l10n key for fixed summary (always provided)
  final String summaryKey;

  /// Extracted deadline / important date (dd.MM.yyyy format), or null
  final String? deadline;

  /// Ordered l10n keys for next steps – resolve via AppLocalizations
  /// e.g. AppLocalizations.of(context).cat_jobcenter_termin_step1
  final List<String> nextStepKeys;

  /// Classification confidence
  final AnalysisConfidence confidence;

  /// Keywords that triggered the classification (useful for debugging)
  final List<String> matchedKeywords;

  /// Trust score as a percentage (0–100)
  final int trustScore;

  /// Full OCR text extracted from the document images.
  final String ocrText;

  const DocumentResult({
    required this.category,
    required this.title,
    required this.summaryKey,
    required this.deadline,
    required this.nextStepKeys,
    required this.confidence,
    required this.matchedKeywords,
    this.trustScore = 0,
    this.ocrText = '',
  });

  Map<String, dynamic> toMap() => {
    'category': category?.toMap(),
    'title': title,
    'summary_key': summaryKey,
    'deadline': deadline,
    'next_step_keys': nextStepKeys,
    'confidence': confidence.name,
    'matched_keywords': matchedKeywords,
    'ocr_text': ocrText,
  };

  @override
  String toString() => toMap().toString();
}

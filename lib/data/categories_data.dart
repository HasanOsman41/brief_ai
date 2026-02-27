// lib/data/categories_data.dart
//
// Single source of truth for all document categories.
// Each category stores a localization [key] and an [icon].
// To add or remove categories, edit [kDocumentCategories] only.

class DocumentCategory {
  const DocumentCategory({required this.key, required this.icon});

  /// The localization key — used to look up the translated label.
  final String key;

  /// Emoji icon shown next to the label in the selector.
  final String icon;
}

const List<DocumentCategory> kDocumentCategories = [
  DocumentCategory(key: 'categoryJobcenter',          icon: '💼'),
  DocumentCategory(key: 'categoryAuslaenderbehoerde',  icon: '🏛️'),
  DocumentCategory(key: 'categoryKrankenkasse',        icon: '🏥'),
  DocumentCategory(key: 'categoryFinanzamt',           icon: '💰'),
  DocumentCategory(key: 'categoryContracts',           icon: '📝'),
  DocumentCategory(key: 'categoryBills',               icon: '🧾'),
  DocumentCategory(key: 'categoryBank',                icon: '🏦'),
  DocumentCategory(key: 'categoryInsurance',           icon: '🛡️'),
  DocumentCategory(key: 'categoryRent',                icon: '🏠'),
  DocumentCategory(key: 'categoryOther',               icon: '📄'),
];

/// Returns the [DocumentCategory] whose key matches [key],
/// or `null` if no match is found.
DocumentCategory? categoryByKey(String key) {
  try {
    return kDocumentCategories.firstWhere((c) => c.key == key);
  } catch (_) {
    return null;
  }
}
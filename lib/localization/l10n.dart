// lib/localization/l10n.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:brief_ai/services/locale_service.dart';

/// Context-free string lookups for code paths that have no [BuildContext],
/// such as scheduling notifications from services or on app startup.
///
/// Mirrors what `AppLocalizations` does with a context, but resolves the
/// active locale from [LocaleService] (SharedPreferences) and loads the
/// matching `assets/lang/<code>.json` directly.
class L10n {
  L10n._();

  static Map<String, String>? _cache;
  static String? _cachedLang;

  static Future<void> _ensureLoaded() async {
    final lang = await LocaleService().getLocale();
    if (_cache != null && _cachedLang == lang) return;
    final jsonString = await rootBundle.loadString('assets/lang/$lang.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    _cache = jsonMap.map((k, v) => MapEntry(k, v.toString()));
    _cachedLang = lang;
  }

  /// Translates [key] in the user's saved locale. Returns [key] unchanged when
  /// there is no matching entry, so free-form text (e.g. a user-edited title)
  /// passes through untouched.
  static Future<String> tr(String key) async {
    await _ensureLoaded();
    return _cache?[key] ?? key;
  }
}

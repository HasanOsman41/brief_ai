import 'dart:convert';

/// Encodes free-form summary + next steps into the existing `summaryKey`
/// column so we don't need a schema migration.
///
/// Translation-key values pass through untouched; only payloads prefixed with
/// [_sentinel] are treated as raw user input.
class RawContent {
  static const String _sentinel = '__raw__';

  final String summary;
  final List<String> steps;

  const RawContent({required this.summary, required this.steps});

  bool get isEmpty => summary.trim().isEmpty && steps.isEmpty;

  /// Serialize to a string safe to store in the `summaryKey` column.
  String encode() {
    return _sentinel +
        jsonEncode({
          'summary': summary,
          'steps': steps,
        });
  }

  /// Returns parsed content when [value] is a raw payload, otherwise null.
  static RawContent? tryDecode(String? value) {
    if (value == null || !value.startsWith(_sentinel)) return null;
    try {
      final decoded = jsonDecode(value.substring(_sentinel.length));
      if (decoded is! Map) return null;
      final summary = decoded['summary'];
      final stepsRaw = decoded['steps'];
      return RawContent(
        summary: summary is String ? summary : '',
        steps: stepsRaw is List
            ? stepsRaw.whereType<String>().toList(growable: false)
            : const [],
      );
    } catch (_) {
      return null;
    }
  }

  /// True when [value] is a raw payload (used to gate display logic).
  static bool isRaw(String? value) =>
      value != null && value.startsWith(_sentinel);
}

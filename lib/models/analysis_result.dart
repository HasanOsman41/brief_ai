// lib/models/analysis_result.dart

class AnalysisResult {
  final String category;
  final String title;
  final String summary;
  final DateTime? deadline;
  final String rawOcrText;

  const AnalysisResult({
    required this.category,
    required this.title,
    required this.summary,
    this.deadline,
    required this.rawOcrText,
  });
}

/// BriefAI – Document Analysis Result Model

class DocumentCategory {
  final String id;
  final String labelDe;
  final String labelAr;
  final RiskLevel riskLevel;

  const DocumentCategory({
    required this.id,
    required this.labelDe,
    required this.labelAr,
    required this.riskLevel,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label_de': labelDe,
        'label_ar': labelAr,
        'risk_level': riskLevel.name,
      };
}

enum RiskLevel { low, medium, high, critical }

enum AnalysisConfidence { high, medium, low, unknown }

class DocumentResult {
  /// Matched category (null if document could not be classified)
  final DocumentCategory? category;

  /// Extracted or derived document title
  final String title;

  /// Short summary extracted from the OCR text
  final String summary;

  /// Extracted deadline / important date (dd.MM.yyyy format), or null
  final String? deadline;

  /// Actionable next steps in the requested language
  final List<String> nextSteps;

  /// Classification confidence
  final AnalysisConfidence confidence;

  /// Keywords that triggered the classification (useful for debugging)
  final List<String> matchedKeywords;

  const DocumentResult({
    required this.category,
    required this.title,
    required this.summary,
    required this.deadline,
    required this.nextSteps,
    required this.confidence,
    required this.matchedKeywords,
  });

  Map<String, dynamic> toMap() => {
        'category': category?.toMap(),
        'title': title,
        'summary': summary,
        'deadline': deadline,
        'next_steps': nextSteps,
        'confidence': confidence.name,
        'matched_keywords': matchedKeywords,
      };

  @override
  String toString() => toMap().toString();
}

/// BriefAI – Category Definition Model

import 'document_result.dart';

class CategoryDefinition {
  final String id;
  final String labelDe;
  final String labelAr;

  /// A single decisive keyword match is enough to classify
  final List<String> decisiveKeywords;

  /// Need 2+ supporting matches when no decisive keyword found
  final List<String> supportingKeywords;

  /// If ANY negative keyword is present, this category is disqualified
  final List<String> negativeKeywords;

  final List<String> nextStepsDe;
  final List<String> nextStepsAr;
  final RiskLevel riskLevel;

  const CategoryDefinition({
    required this.id,
    required this.labelDe,
    required this.labelAr,
    required this.decisiveKeywords,
    required this.supportingKeywords,
    required this.negativeKeywords,
    required this.nextStepsDe,
    required this.nextStepsAr,
    required this.riskLevel,
  });
}

/// BriefAI Analysis Service Interface
///
/// Provides abstraction for document analysis supporting both offline and online modes.
/// This interface allows switching between different analysis implementations based on
/// availability and user preferences.

import '../models/document_result.dart';

/// Abstract interface for document analysis services.
///
/// Implementations should provide:
/// - Document classification and categorization
/// - Deadline extraction from images
/// - Confidence scoring for analysis results
/// - Service availability status
abstract class AnalysisService {
  /// Analyzes document images and returns structured document information.
  ///
  /// Takes a list of image paths as input, performs OCR internally,
  /// and returns a [DocumentResult] containing:
  /// - Document category and classification
  /// - Extracted deadlines and important dates
  /// - Analysis confidence level
  /// - Matched keywords that triggered the classification
  ///
  /// The optional [onProgress] callback reports OCR progress as (current, total).
  ///
  /// Returns [DocumentResult] with unknown confidence if analysis fails.
  Future<DocumentResult> analyze(
    List<String> imagePaths, {
    void Function(int current, int total)? onProgress,
  });

  /// Returns true if this service is currently available for use.
  ///
  /// Online services may return false if network is unavailable or
  /// API limits are exceeded. Offline services should typically return true.
  bool get isAvailable;

  /// Returns a human-readable name for this analysis service.
  ///
  /// Used for UI display and logging purposes.
  String get serviceName;
}

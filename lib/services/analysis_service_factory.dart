/// BriefAI – Analysis Service Factory
///
/// Factory for creating and managing analysis services.

import 'analysis_service.dart';
import 'analysis_service_impl/offline_analysis_service.dart';
import 'analysis_service_impl/online_analysis_service.dart';

/// Analysis modes supported by the application.
enum AnalysisMode { offline, online }

/// Factory for creating analysis services based on the selected mode.
class AnalysisServiceFactory {
  static final AnalysisServiceFactory _instance = AnalysisServiceFactory._();
  static AnalysisServiceFactory get instance => _instance;

  AnalysisServiceFactory._();

  AnalysisMode _currentMode = AnalysisMode.offline;

  /// Gets the current analysis mode.
  AnalysisMode get currentMode => _currentMode;

  /// Sets the analysis mode (for future use when online mode is available).
  void setMode(AnalysisMode mode) {
    _currentMode = mode;
  }

  /// Creates an analysis service for the current mode.
  AnalysisService createService() {
    switch (_currentMode) {
      case AnalysisMode.offline:
        return OfflineAnalysisService();
      case AnalysisMode.online:
        return OnlineAnalysisService();
    }
  }

  /// Gets the default analysis service (offline).
  AnalysisService getDefaultService() {
    return OfflineAnalysisService();
  }

  /// Checks if online analysis is available.
  bool get isOnlineAvailable => OnlineAnalysisService().isAvailable;
}

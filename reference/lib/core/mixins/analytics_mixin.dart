import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScreenView();
    });
  }

  void _logScreenView() {
    final screenName = runtimeType.toString().replaceAll('State', '');
    context.read<FirebaseService>().logScreenView(screenName);
  }

  void logEvent(String eventName, Map<String, dynamic> parameters) {
    context.read<FirebaseService>().logEvent(eventName, parameters);
  }

  // User Engagement Analytics
  void logUserEngagement({
    required String action,
    required String contentType,
    required String contentId,
    Map<String, dynamic>? extraParams,
  }) {
    final params = {
      'action': action,
      'content_type': contentType,
      'content_id': contentId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extraParams,
    };
    logEvent('user_engagement', params);
  }

  // Content Performance Analytics
  void logContentImpression({
    required String contentType,
    required String contentId,
    required String section,
    String? source,
  }) {
    final params = {
      'content_type': contentType,
      'content_id': contentId,
      'section': section,
      'source': source ?? 'main_feed',
      'timestamp': DateTime.now().toIso8601String(),
    };
    logEvent('content_impression', params);
  }

  // Error Analytics
  void logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final params = {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    };
    logEvent('app_error', params);
  }

  // Feature Usage Analytics
  void logFeatureUsage({
    required String featureName,
    required String action,
    Map<String, dynamic>? parameters,
  }) {
    final params = {
      'feature': featureName,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    };
    logEvent('feature_usage', params);
  }

  // Search Analytics
  void logSearch({
    required String query,
    required String contentType,
    required int resultCount,
    Map<String, dynamic>? filters,
  }) {
    final params = {
      'query': query,
      'content_type': contentType,
      'result_count': resultCount,
      'filters': filters,
      'timestamp': DateTime.now().toIso8601String(),
    };
    logEvent('search_performed', params);
  }

  // Performance Analytics
  void logPerformanceMetric({
    required String metricName,
    required double value,
    String? context,
  }) {
    final params = {
      'metric_name': metricName,
      'value': value,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    };
    logEvent('performance_metric', params);
  }
}

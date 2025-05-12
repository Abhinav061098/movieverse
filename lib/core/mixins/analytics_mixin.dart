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
}

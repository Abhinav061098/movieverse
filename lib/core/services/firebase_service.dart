import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAnalytics analytics;
  late final FirebaseMessaging messaging;
  late final FirebasePerformance performance;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Analytics
      analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);

      // Initialize Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Initialize Performance Monitoring
      performance = FirebasePerformance.instance;
      await performance.setPerformanceCollectionEnabled(true);

      // Initialize Cloud Messaging
      messaging = FirebaseMessaging.instance;
      await _initializeMessaging();
    } catch (e, stack) {
      debugPrint('Error initializing Firebase: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _initializeMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle token refresh
      messaging.onTokenRefresh.listen((token) {
        debugPrint('FCM Token refreshed: $token');
        // TODO: Send this token to your server
      });

      // Handle messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');
        }
      });
    }
  }

  // Analytics tracking methods
  Future<void> logScreenView(String screenName) async {
    await analytics.setCurrentScreen(screenName: screenName);
  }

  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  // Performance monitoring methods
  Trace startTrace(String name) {
    return performance.newTrace(name);
  }

  HttpMetric startHttpMetric(String url, HttpMethod method) {
    return performance.newHttpMetric(url, method);
  }
}

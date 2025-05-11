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
}

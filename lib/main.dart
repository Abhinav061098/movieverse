import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/api/api_client.dart';
import 'core/services/firebase_service.dart';

import 'features/movies/services/movie_service.dart';
import 'features/movies/services/tv_service.dart';
import 'features/movies/viewmodels/movie_view_model.dart';
import 'features/movies/viewmodels/tv_show_view_model.dart';
import 'features/movies/views/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and notifications
  await FirebaseService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final movieService = MovieService(apiClient);
    final tvService = TvService(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MovieViewModel(movieService),
        ),
        ChangeNotifierProvider(
          create: (_) => TvShowViewModel(tvService),
        ),
        Provider.value(value: FirebaseService()),
      ],
      child: MaterialApp(
        title: 'MovieVerse',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseService().analytics),
        ],
        home: const HomeScreen(),
      ),
    );
  }
}

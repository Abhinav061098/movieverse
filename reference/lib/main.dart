import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/api/api_client.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/auth_service.dart';
import 'features/movies/services/movie_service.dart';
import 'features/movies/services/tv_service.dart';
import 'features/movies/services/favorites_service.dart';
import 'features/movies/services/watchlist_service.dart';
import 'features/movies/viewmodels/media_list_viewmodel.dart';
import 'features/movies/views/screens/home_screen.dart';
import 'features/auth/screens/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and notifications
  await FirebaseService().initialize();
  await NotificationService().initialize();

  final favoritesService = await FavoritesService.create();
  final watchlistService = await WatchlistService.create();
  runApp(MyApp(
    favoritesService: favoritesService,
    watchlistService: watchlistService,
  ));
}

class MyApp extends StatelessWidget {
  final FavoritesService favoritesService;
  final WatchlistService watchlistService;

  const MyApp({
    super.key,
    required this.favoritesService,
    required this.watchlistService,
  });

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final movieService = MovieService(() => apiClient.getDio);
    final tvService = TvService(apiClient.getDio);
    final authService = AuthService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MediaListViewModel(movieService, tvService),
        ),
        ChangeNotifierProvider<FavoritesService>.value(value: favoritesService),
        ChangeNotifierProvider<WatchlistService>.value(value: watchlistService),
        Provider.value(value: FirebaseService()),
        Provider.value(value: NotificationService()),
        Provider.value(value: authService),
        StreamProvider(
          create: (_) => authService.authStateChanges,
          initialData: null,
        ),
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
        home: StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return const HomeScreen();
            }
            return const AuthWrapper();
          },
        ),
      ),
    );
  }
}

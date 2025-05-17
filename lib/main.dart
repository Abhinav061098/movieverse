import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/api/api_client.dart';
import 'core/services/firebase_service.dart';
import 'features/movies/services/movie_service.dart';
import 'features/movies/services/tv_service.dart';
import 'features/movies/services/favorites_service.dart';
import 'features/movies/services/watchlist_service.dart';
import 'features/movies/viewmodels/movie_view_model.dart';
import 'features/movies/viewmodels/tv_show_view_model.dart';
import 'features/movies/views/screens/home_screen.dart';
import 'core/auth/screens/sign_up_screen.dart';
import 'core/auth/screens/sign_in_screen.dart';
import 'features/movies/views/screens/movie_details_screen.dart';
import 'features/movies/views/screens/tv_show_details_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    debugPrint('Starting app initialization...');

    // Initialize Firebase first
    final firebaseService = FirebaseService();
    await firebaseService.initialize();

    debugPrint('Firebase initialized successfully');

    // Now it's safe to use Firebase services
    final auth = FirebaseAuth.instance;
    debugPrint('Auth state at startup: ${auth.currentUser?.uid}');

    // Initialize WatchlistService
    final watchlistService = await WatchlistService.create();
    debugPrint('WatchlistService initialized successfully');

    // Test database connection if user is authenticated
    if (auth.currentUser != null) {
      await firebaseService.testDatabaseConnection();
    }

    runApp(AppRoot(watchlistService: watchlistService));
  } catch (e) {
    debugPrint('Error in main: $e');
    rethrow;
  }
}

class AppRoot extends StatelessWidget {
  final WatchlistService watchlistService;

  const AppRoot({
    super.key,
    required this.watchlistService,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final apiClient = ApiClient();
    final movieService = MovieService(apiClient);
    final tvService = TvService(apiClient);
    return MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        ChangeNotifierProvider<WatchlistService>.value(value: watchlistService),
        StreamProvider<User?>(
          initialData: null,
          create: (_) => FirebaseAuth.instance.authStateChanges(),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieViewModel(movieService),
        ),
        ChangeNotifierProvider(
          create: (_) => TvShowViewModel(tvService),
        ),
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService(),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return MaterialApp(
      title: 'MovieVerse',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: firebaseService.analytics),
      ],
      routes: {
        // SignUpScreen should navigate to SignInScreen after successful registration
        '/sign-up': (context) => SignUpScreen(
              onSignInPressed: () =>
                  Navigator.pushReplacementNamed(context, '/sign-in'),
            ),
        '/home': (context) => const HomeScreen(),
        '/sign-in': (context) => const SignInScreen(),
        '/movieDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is int) {
            return MovieDetailsScreen(movieId: args);
          }
          return const Scaffold(body: Center(child: Text('Invalid movie ID')));
        },
        '/tvShowDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is int) {
            return TvShowDetailsScreen(tvShowId: args);
          }
          return const Scaffold(
              body: Center(child: Text('Invalid TV show ID')));
        },
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          // When authenticated, show HomeScreen
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // When not authenticated, always show SignInScreen
          return const SignInScreen();
        },
      ),
    );
  }
}

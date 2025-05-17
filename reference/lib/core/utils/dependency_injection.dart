import 'package:get_it/get_it.dart';
import '../../features/movies/services/movie_service.dart';
import '../../features/movies/viewmodels/movie_list_viewmodel.dart';
import '../api/api_client.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // API
  getIt.registerLazySingleton(() => ApiClient());

  // Services
  getIt.registerLazySingleton(() => MovieService(getIt()));

  // ViewModels
  getIt.registerFactory(() => MovieListViewModel(getIt()));
}

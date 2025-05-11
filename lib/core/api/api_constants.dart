class ApiConstants {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String apiKey = 'e0bebc27ad74af143b2d1c15b6e5a6d1';
  static const String accessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJlMGJlYmMyN2FkNzRhZjE0M2IyZDFjMTViNmU1YTZkMSIsInN1YiI6IjY4MTRlNTlkYzNlN2UwOWZhYzkwN2NlMyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.xMw-GlhH-ydMKySRfVesU0HrtuG7kN1CVWWYB9tnRc8';

  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/';
  static const String imageUrlW500 = '${imageBaseUrl}w500';
  static const String imageUrlOriginal = '${imageBaseUrl}original';

  // Movie Endpoints
  static const String popularMovies = '/movie/popular';
  static const String topRatedMovies = '/movie/top_rated';
  static const String upcomingMovies = '/movie/upcoming';
  static const String movieDetails = '/movie/';
  static const String searchMovie = '/search/movie';
  static const String movieVideos = '/movie/{movie_id}/videos';
  static const String movieGenres = '/genre/movie/list';

  // TV Show Endpoints
  static const String popularTvShows = '/tv/popular';
  static const String topRatedTvShows = '/tv/top_rated';
  static const String airingTodayTvShows = '/tv/airing_today';
  static const String onTheAirTvShows = '/tv/on_the_air';
  static const String tvShowDetails = '/tv/';
  static const String tvShowVideos = '/tv/{tv_id}/videos';
  static const String tvGenres = '/genre/tv/list';

  // YouTube
  static const String youtubeWatchUrl = 'https://www.youtube.com/watch?v=';
  static const String youtubeThumbUrl = 'https://img.youtube.com/vi/';
}

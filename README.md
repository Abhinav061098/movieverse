# MovieVerse 🎬

A modern Flutter application for browsing movies and TV shows, built with a beautiful UI and comprehensive features.

## Features 🌟

- **Movie & TV Show Discovery**
  - Browse popular movies and TV shows
  - Search functionality with history
  - Genre-based filtering
  - Movie of the day highlights
  - Mood-based movie recommendations

- **Detailed Information**
  - Comprehensive movie and TV show details
  - Cast and crew information
  - Director profiles and filmography
  - Reviews and ratings
  - Trailers and videos
  - Social media links

- **Personal Features**
  - User authentication
  - Favorites list
  - Watchlist management
  - Profile customization
  - Search history

- **Technical Features**
  - Offline support
  - Image caching
  - Responsive design
  - Dark theme
  - Smooth animations

## Tech Stack 🛠

- **Framework**: Flutter
- **State Management**: Provider
- **Backend**: Firebase
  - Authentication
  - Realtime Database
  - Analytics
  - Crashlytics
- **API Integration**: TMDB API
- **Dependencies**:
  - `dio` for networking
  - `cached_network_image` for image caching
  - `youtube_player_iframe` for trailers
  - `connectivity_plus` for network state
  - `shimmer` for loading effects
  - `font_awesome_flutter` for icons

## Getting Started 🚀

1. **Prerequisites**
   - Flutter SDK (>=3.2.3)
   - Dart SDK (>=3.2.3)
   - Android Studio / VS Code
   - Firebase account

2. **Installation**
   ```bash
   # Clone the repository
   git clone https://github.com/Abhinav061098/movieverse.git

   # Navigate to project directory
   cd movieverse

   # Install dependencies
   flutter pub get

   # Run the app
   flutter run
   ```

3. **Configuration**
   - Set up Firebase project
   - Add your TMDB API key
   - Configure Firebase services

## Project Structure 📁

```
lib/
├── core/
│   ├── api/
│   ├── auth/
│   ├── services/
│   └── utils/
├── features/
│   └── movies/
│       ├── models/
│       ├── services/
│       ├── viewmodels/
│       └── views/
└── main.dart
```

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License 📝

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- TMDB for their comprehensive movie and TV show database
- Flutter team for the amazing framework
- All contributors who have helped shape this project

## Contact 📧

Abhinav - [@Abhinav061098](https://github.com/Abhinav061098)

Project Link: [https://github.com/Abhinav061098/movieverse](https://github.com/Abhinav061098/movieverse)

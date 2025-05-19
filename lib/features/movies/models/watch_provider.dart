import 'package:json_annotation/json_annotation.dart';
import 'dart:developer' as developer;

part 'watch_provider.g.dart';

@JsonSerializable()
class WatchProvider {
  @JsonKey(name: 'provider_id')
  final int id;
  @JsonKey(name: 'provider_name')
  final String name;
  @JsonKey(name: 'logo_path')
  final String? logoPath;
  @JsonKey(name: 'display_priority')
  final int displayPriority;
  @JsonKey(name: 'link')
  final String? link;

  const WatchProvider({
    required this.id,
    required this.name,
    this.logoPath,
    required this.displayPriority,
    this.link,
  });

  factory WatchProvider.fromJson(Map<String, dynamic> json) {
    developer.log('Parsing WatchProvider from JSON: $json');
    developer.log('Provider ID: ${json['provider_id']}');
    developer.log('Provider Name: ${json['provider_name']}');
    developer.log('Logo Path: ${json['logo_path']}');
    developer.log('Display Priority: ${json['display_priority']}');
    developer.log('All provider fields: ${json.keys.join(', ')}');

    return WatchProvider(
      id: json['provider_id'] ?? 0,
      name: json['provider_name'] ?? '',
      logoPath: json['logo_path'],
      displayPriority: json['display_priority'] ?? 0,
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() => _$WatchProviderToJson(this);

  String get fullLogoPath =>
      logoPath != null ? 'https://image.tmdb.org/t/p/original$logoPath' : '';
}

@JsonSerializable()
class WatchProviders {
  @JsonKey(defaultValue: [])
  final List<WatchProvider> flatrate;
  @JsonKey(defaultValue: [])
  final List<WatchProvider> rent;
  @JsonKey(defaultValue: [])
  final List<WatchProvider> buy;
  @JsonKey(defaultValue: [])
  final List<WatchProvider> free;
  final String? link;

  const WatchProviders({
    required this.flatrate,
    required this.rent,
    required this.buy,
    required this.free,
    this.link,
  });

  factory WatchProviders.fromJson(Map<String, dynamic> json) {
    developer.log('WatchProviders.fromJson received: $json');
    developer.log('Available fields in json: ${json.keys.join(', ')}');

    try {
      // Parse the providers directly from the JSON
      final flatrate = (json['flatrate'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      developer.log('Parsed flatrate providers: ${flatrate.length}');

      final rent = (json['rent'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      developer.log('Parsed rent providers: ${rent.length}');

      final buy = (json['buy'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      developer.log('Parsed buy providers: ${buy.length}');

      final free = (json['free'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      developer.log('Parsed free providers: ${free.length}');

      final link = json['link'] as String?;
      developer.log('General link: $link');

      final providers = WatchProviders(
        flatrate: flatrate,
        rent: rent,
        buy: buy,
        free: free,
        link: link,
      );

      developer.log('Successfully parsed providers: ${providers.toJson()}');
      return providers;
    } catch (e, stackTrace) {
      developer.log(
        'Error parsing watch providers',
        error: e,
        stackTrace: stackTrace,
      );
      return const WatchProviders(
        flatrate: [],
        rent: [],
        buy: [],
        free: [],
      );
    }
  }

  Map<String, dynamic> toJson() => _$WatchProvidersToJson(this);

  bool get hasAnyProvider =>
      flatrate.isNotEmpty ||
      rent.isNotEmpty ||
      buy.isNotEmpty ||
      free.isNotEmpty;
}

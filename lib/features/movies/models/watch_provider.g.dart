// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchProvider _$WatchProviderFromJson(Map<String, dynamic> json) =>
    WatchProvider(
      id: (json['provider_id'] as num).toInt(),
      name: json['provider_name'] as String,
      logoPath: json['logo_path'] as String?,
      displayPriority: (json['display_priority'] as num).toInt(),
    );

Map<String, dynamic> _$WatchProviderToJson(WatchProvider instance) =>
    <String, dynamic>{
      'provider_id': instance.id,
      'provider_name': instance.name,
      'logo_path': instance.logoPath,
      'display_priority': instance.displayPriority,
    };

WatchProviders _$WatchProvidersFromJson(Map<String, dynamic> json) =>
    WatchProviders(
      flatrate: (json['flatrate'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rent: (json['rent'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      buy: (json['buy'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      free: (json['free'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      link: json['link'] as String?,
    );

Map<String, dynamic> _$WatchProvidersToJson(WatchProviders instance) =>
    <String, dynamic>{
      'flatrate': instance.flatrate,
      'rent': instance.rent,
      'buy': instance.buy,
      'free': instance.free,
      'link': instance.link,
    };

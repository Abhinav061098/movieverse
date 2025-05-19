// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      id: json['id'] as String,
      author: json['author'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      authorDetails: AuthorDetails.fromJson(
          json['author_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'content': instance.content,
      'created_at': instance.createdAt,
      'author_details': instance.authorDetails,
    };

AuthorDetails _$AuthorDetailsFromJson(Map<String, dynamic> json) =>
    AuthorDetails(
      name: json['name'] as String,
      username: json['username'] as String,
      avatarPath: json['avatar_path'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AuthorDetailsToJson(AuthorDetails instance) =>
    <String, dynamic>{
      'name': instance.name,
      'username': instance.username,
      'avatar_path': instance.avatarPath,
      'rating': instance.rating,
    };

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'review.g.dart';

@JsonSerializable()
class Review extends Equatable {
  final String id;
  final String author;
  final String content;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'author_details')
  final AuthorDetails authorDetails;

  const Review({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.authorDetails,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  @override
  List<Object?> get props => [id, author, content, createdAt, authorDetails];
}

@JsonSerializable()
class AuthorDetails extends Equatable {
  final String name;
  final String username;
  @JsonKey(name: 'avatar_path')
  final String? avatarPath;
  final double? rating;

  const AuthorDetails({
    required this.name,
    required this.username,
    this.avatarPath,
    this.rating,
  });

  factory AuthorDetails.fromJson(Map<String, dynamic> json) =>
      _$AuthorDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorDetailsToJson(this);

  @override
  List<Object?> get props => [name, username, avatarPath, rating];
}

import 'package:equatable/equatable.dart';

class Subreddit with EquatableMixin {
  final String id;
  final String name;
  final String? description;
  final int subscriberCount;
  final bool isNsfw;
  final bool isSubscribed;
  final String? iconUrl;
  final String? bannerUrl;

  const Subreddit({
    required this.id,
    required this.name,
    this.description,
    this.subscriberCount = 0,
    this.isNsfw = false,
    this.isSubscribed = false,
    this.iconUrl,
    this.bannerUrl,
  });

  String get displayName => 'r/$name';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        subscriberCount,
        isNsfw,
        isSubscribed,
        iconUrl,
        bannerUrl,
      ];
}

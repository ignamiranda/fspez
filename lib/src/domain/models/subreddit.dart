import 'package:equatable/equatable.dart';

class Subreddit with EquatableMixin {
  final String id;
  final String name;
  final String? description;
  final String? sidebarDescription;
  final int subscriberCount;
  final int? activeUserCount;
  final DateTime? createdAt;
  final bool isNsfw;
  final bool isQuarantined;
  final bool isSubscribed;
  final String? subredditType;
  final String? iconUrl;
  final String? bannerUrl;

  const Subreddit({
    required this.id,
    required this.name,
    this.description,
    this.sidebarDescription,
    this.subscriberCount = 0,
    this.activeUserCount,
    this.createdAt,
    this.isNsfw = false,
    this.isQuarantined = false,
    this.isSubscribed = false,
    this.subredditType,
    this.iconUrl,
    this.bannerUrl,
  });

  String get displayName => 'r/$name';

  bool get isRestricted => subredditType == 'restricted';

  bool get isPrivate => subredditType == 'private';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        sidebarDescription,
        subscriberCount,
        activeUserCount,
        createdAt,
        isNsfw,
        isQuarantined,
        isSubscribed,
        subredditType,
        iconUrl,
        bannerUrl,
      ];
}

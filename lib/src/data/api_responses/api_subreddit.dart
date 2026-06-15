import '../../domain/models/subreddit.dart';

class ApiSubreddit {
  final String id;
  final String displayName;
  final String? publicDescription;
  final String? description;
  final int subscribers;
  final int? activeUserCount;
  final int? createdUtc;
  final bool over18;
  final bool quarantine;
  final bool userIsSubscriber;
  final String? subredditType;
  final String? iconImg;
  final String? communityIcon;
  final String? bannerImg;
  final String? bannerBackgroundImage;

  ApiSubreddit({
    required this.id,
    required this.displayName,
    this.publicDescription,
    this.description,
    required this.subscribers,
    this.activeUserCount,
    this.createdUtc,
    required this.over18,
    required this.quarantine,
    required this.userIsSubscriber,
    this.subredditType,
    this.iconImg,
    this.communityIcon,
    this.bannerImg,
    this.bannerBackgroundImage,
  });

  factory ApiSubreddit.fromJson(Map<String, dynamic> data) {
    return ApiSubreddit(
      id: data['id'] as String? ?? '',
      displayName: data['display_name'] as String? ?? '',
      publicDescription: data['public_description'] as String?,
      description: data['description'] as String?,
      subscribers: data['subscribers'] as int? ?? 0,
      activeUserCount: (data['active_user_count'] as num?)?.toInt(),
      createdUtc: (data['created_utc'] as num?)?.toInt(),
      over18: data['over18'] as bool? ?? false,
      quarantine: data['quarantine'] as bool? ?? false,
      userIsSubscriber: data['user_is_subscriber'] as bool? ?? false,
      subredditType: data['subreddit_type'] as String?,
      iconImg: data['icon_img'] as String?,
      communityIcon: data['community_icon'] as String?,
      bannerImg: data['banner_img'] as String?,
      bannerBackgroundImage: data['banner_background_image'] as String?,
    );
  }

  Subreddit toDomain(String fallbackName) {
    return Subreddit(
      id: id,
      name: displayName.isNotEmpty ? displayName : fallbackName,
      description: publicDescription,
      sidebarDescription: description,
      subscriberCount: subscribers,
      activeUserCount: activeUserCount,
      createdAt: createdUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdUtc! * 1000),
      isNsfw: over18,
      isQuarantined: quarantine,
      isSubscribed: userIsSubscriber,
      subredditType: subredditType,
      iconUrl: _iconUrl(),
      bannerUrl: bannerImg ?? bannerBackgroundImage,
    );
  }

  String? _iconUrl() {
    final raw = iconImg;
    if (raw != null && raw.isNotEmpty) {
      return raw.replaceAll('&amp;', '&');
    }
    final fallback = communityIcon;
    if (fallback != null && fallback.isNotEmpty) {
      return fallback.replaceAll('&amp;', '&');
    }
    return null;
  }
}

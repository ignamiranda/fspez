import '../domain/models/subreddit.dart';
import '../domain/models/subreddit_rule.dart';
import 'shreddit_json_extractor.dart';

class HtmlSubredditParser {
  Subreddit parseInfo(String html, String name) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final raw = pageProps['subreddit'] as Map<String, dynamic>? ??
        pageProps['about'] as Map<String, dynamic>? ??
        {};

    final id = raw['id'] as String? ?? '';
    final displayName =
        raw['displayName'] as String? ?? raw['display_name'] as String? ?? name;
    final publicDescription = raw['publicDescription'] as String? ??
        raw['public_description'] as String?;
    final description = raw['description'] as String?;
    final subscribers = _int(raw, 'subscribers') ?? 0;
    final activeUserCount =
        _int(raw, 'activeUserCount') ?? _int(raw, 'active_user_count');
    final createdUtc = _int(raw, 'createdUtc') ?? _int(raw, 'created_utc') ?? 0;
    final over18 = _bool(raw, 'over18') ?? _bool(raw, 'over_18') ?? false;
    final quarantine = _bool(raw, 'quarantine') ?? false;
    final userIsSubscriber = _bool(raw, 'userIsSubscriber') ??
        _bool(raw, 'user_is_subscriber') ??
        false;
    final subredditType =
        raw['subredditType'] as String? ?? raw['subreddit_type'] as String?;
    final iconImg = raw['iconImg'] as String? ?? raw['icon_img'] as String?;
    final communityIcon =
        raw['communityIcon'] as String? ?? raw['community_icon'] as String?;
    final bannerImg =
        raw['bannerImg'] as String? ?? raw['banner_img'] as String?;

    final iconUrl = _resolveIconUrl(iconImg, communityIcon);

    return Subreddit(
      id: id,
      name: displayName,
      description: publicDescription,
      sidebarDescription: description,
      subscriberCount: subscribers,
      activeUserCount: activeUserCount,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : null,
      isNsfw: over18,
      isQuarantined: quarantine,
      isSubscribed: userIsSubscriber,
      subredditType: subredditType,
      iconUrl: iconUrl,
      bannerUrl: bannerImg,
    );
  }

  List<SubredditRule> parseRules(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawRules = pageProps['rules'] as List<dynamic>? ??
        pageProps['subredditRules'] as List<dynamic>? ??
        [];

    return rawRules.whereType<Map<String, dynamic>>().map((raw) {
      final priority = _int(raw, 'priority') ?? 0;
      return SubredditRule(
        shortName: raw['shortName'] as String? ??
            raw['short_name'] as String? ??
            priority.toString(),
        description: raw['description'] as String? ?? '',
        kind: raw['kind'] as String? ?? 'all',
        violationReason: raw['violationReason'] as String? ??
            raw['violation_reason'] as String?,
        priority: priority,
      );
    }).toList();
  }

  String? _resolveIconUrl(String? iconImg, String? communityIcon) {
    if (iconImg != null && iconImg.isNotEmpty) {
      return iconImg.replaceAll('&amp;', '&');
    }
    if (communityIcon != null && communityIcon.isNotEmpty) {
      return communityIcon.replaceAll('&amp;', '&');
    }
    return null;
  }

  Map<String, dynamic> _pageProps(Map<String, dynamic> extracted) {
    final props = extracted['props'] as Map<String, dynamic>?;
    if (props == null) return extracted;
    return props['pageProps'] as Map<String, dynamic>? ?? extracted;
  }

  int? _int(Map<String, dynamic> map, String key) => map[key] as int?;
  bool? _bool(Map<String, dynamic> map, String key) => map[key] as bool?;
}

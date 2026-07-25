import '../domain/models/subreddit.dart';
import '../domain/models/subreddit_rule.dart';
import 'html_parser_utils.dart';
import 'shreddit_json_extractor.dart';

class HtmlSubredditParser {
  Subreddit parseInfo(String html, String name) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final raw = pp['subreddit'] as Map<String, dynamic>? ??
        pp['about'] as Map<String, dynamic>? ??
        {};

    final id = raw['id'] as String? ?? '';
    final displayName =
        raw['displayName'] as String? ?? raw['display_name'] as String? ?? name;
    final publicDescription = raw['publicDescription'] as String? ??
        raw['public_description'] as String?;
    final description = raw['description'] as String?;
    final subscribers = intOr(raw, 'subscribers') ?? 0;
    final activeUserCount =
        intOr(raw, 'activeUserCount') ?? intOr(raw, 'active_user_count');
    final createdUtc =
        intOr(raw, 'createdUtc') ?? intOr(raw, 'created_utc') ?? 0;
    final over18 = boolOr(raw, 'over18') ?? boolOr(raw, 'over_18') ?? false;
    final quarantine = boolOr(raw, 'quarantine') ?? false;
    final userIsSubscriber = boolOr(raw, 'userIsSubscriber') ??
        boolOr(raw, 'user_is_subscriber') ??
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
    final pp = pageProps(extracted);

    final rawRules = pp['rules'] as List<dynamic>? ??
        pp['subredditRules'] as List<dynamic>? ??
        [];

    return rawRules.whereType<Map<String, dynamic>>().map((raw) {
      final priority = intOr(raw, 'priority') ?? 0;
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
}

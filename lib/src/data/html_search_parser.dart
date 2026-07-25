import '../domain/enums/feed_sort.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/search_user.dart';
import '../domain/models/subreddit.dart';
import 'html_parser_utils.dart';
import 'shreddit_json_extractor.dart';

class HtmlSearchParser {
  Feed parsePosts(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final rawPosts = pp['posts'] as List<dynamic>? ??
        pp['searchResults'] as List<dynamic>? ??
        [];
    final posts =
        rawPosts.whereType<Map<String, dynamic>>().map(_postFromRaw).toList();
    final after = pp['after'] as String?;

    return Feed(
      kind: FeedKind.popular,
      sort: FeedSort.new_,
      posts: posts,
      after: after,
    );
  }

  List<Subreddit> parseCommunities(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final rawSubreddits = pp['subreddits'] as List<dynamic>? ??
        pp['communities'] as List<dynamic>? ??
        [];
    return rawSubreddits.whereType<Map<String, dynamic>>().map((raw) {
      final displayName = raw['displayName'] as String? ??
          raw['display_name'] as String? ??
          raw['name'] as String? ??
          '';
      return Subreddit(
        id: raw['id'] as String? ?? '',
        name: displayName,
        description: raw['publicDescription'] as String? ??
            raw['public_description'] as String?,
        subscriberCount: intOr(raw, 'subscribers') ?? 0,
        iconUrl: _resolveIcon(raw),
      );
    }).toList();
  }

  List<SearchUser> parseUsers(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final rawUsers = pp['users'] as List<dynamic>? ??
        pp['searchUsers'] as List<dynamic>? ??
        [];
    return rawUsers.whereType<Map<String, dynamic>>().map((raw) {
      return SearchUser(
        name: raw['name'] as String? ?? raw['username'] as String? ?? '',
        linkKarma: intOr(raw, 'linkKarma') ?? intOr(raw, 'link_karma') ?? 0,
        commentKarma:
            intOr(raw, 'commentKarma') ?? intOr(raw, 'comment_karma') ?? 0,
        iconImg: raw['iconImg'] as String? ?? raw['icon_img'] as String?,
        isGold: boolOr(raw, 'isGold') ?? boolOr(raw, 'is_gold') ?? false,
        isMod: boolOr(raw, 'isMod') ?? boolOr(raw, 'is_mod') ?? false,
      );
    }).toList();
  }

  Post _postFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final title = raw['title'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final subreddit = raw['subreddit'] as String? ?? '';
    final subredditId = raw['subreddit_id'] as String? ?? '';
    final score = intOr(raw, 'score') ?? 0;
    final numComments =
        intOr(raw, 'numComments') ?? intOr(raw, 'num_comments') ?? 0;
    final createdUtc =
        intOr(raw, 'createdUtc') ?? intOr(raw, 'created_utc') ?? 0;
    final permalink = raw['permalink'] as String? ?? '';

    return Post(
      id: id,
      title: title,
      author: author,
      subreddit: Subreddit(id: subredditId, name: subreddit),
      score: score,
      commentCount: numComments,
      vote: parseVote(raw['likes']),
      isNsfw: boolOr(raw, 'over_18') ?? boolOr(raw, 'over18') ?? false,
      isSpoiler: boolOr(raw, 'spoiler') ?? false,
      isSaved: boolOr(raw, 'saved') ?? false,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      permalink: permalink,
      type: PostType.link,
    );
  }

  String? _resolveIcon(Map<String, dynamic> raw) {
    final icon = raw['iconImg'] as String? ?? raw['icon_img'] as String?;
    if (icon != null && icon.isNotEmpty) return icon.replaceAll('&amp;', '&');
    final communityIcon =
        raw['communityIcon'] as String? ?? raw['community_icon'] as String?;
    if (communityIcon != null && communityIcon.isNotEmpty) {
      return communityIcon.replaceAll('&amp;', '&');
    }
    return null;
  }
}

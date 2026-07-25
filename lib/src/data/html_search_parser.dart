import '../domain/enums/feed_sort.dart';
import '../domain/enums/vote_direction.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/search_user.dart';
import '../domain/models/subreddit.dart';
import 'shreddit_json_extractor.dart';

class HtmlSearchParser {
  Feed parsePosts(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawPosts = pageProps['posts'] as List<dynamic>? ??
        pageProps['searchResults'] as List<dynamic>? ??
        [];
    final posts =
        rawPosts.whereType<Map<String, dynamic>>().map(_postFromRaw).toList();
    final after = pageProps['after'] as String?;

    return Feed(
      kind: FeedKind.popular,
      sort: FeedSort.new_,
      posts: posts,
      after: after,
    );
  }

  List<Subreddit> parseCommunities(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawSubreddits = pageProps['subreddits'] as List<dynamic>? ??
        pageProps['communities'] as List<dynamic>? ??
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
        subscriberCount: _int(raw, 'subscribers') ?? 0,
        iconUrl: _resolveIcon(raw),
      );
    }).toList();
  }

  List<SearchUser> parseUsers(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawUsers = pageProps['users'] as List<dynamic>? ??
        pageProps['searchUsers'] as List<dynamic>? ??
        [];
    return rawUsers.whereType<Map<String, dynamic>>().map((raw) {
      return SearchUser(
        name: raw['name'] as String? ?? raw['username'] as String? ?? '',
        linkKarma: _int(raw, 'linkKarma') ?? _int(raw, 'link_karma') ?? 0,
        commentKarma:
            _int(raw, 'commentKarma') ?? _int(raw, 'comment_karma') ?? 0,
        iconImg: raw['iconImg'] as String? ?? raw['icon_img'] as String?,
        isGold: _bool(raw, 'isGold') ?? _bool(raw, 'is_gold') ?? false,
        isMod: _bool(raw, 'isMod') ?? _bool(raw, 'is_mod') ?? false,
      );
    }).toList();
  }

  Post _postFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final title = raw['title'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final subreddit = raw['subreddit'] as String? ?? '';
    final subredditId = raw['subreddit_id'] as String? ?? '';
    final score = _int(raw, 'score') ?? 0;
    final numComments =
        _int(raw, 'numComments') ?? _int(raw, 'num_comments') ?? 0;
    final createdUtc = _int(raw, 'createdUtc') ?? _int(raw, 'created_utc') ?? 0;
    final permalink = raw['permalink'] as String? ?? '';

    return Post(
      id: id,
      title: title,
      author: author,
      subreddit: Subreddit(id: subredditId, name: subreddit),
      score: score,
      commentCount: numComments,
      vote: _parseVote(raw['likes']),
      isNsfw: _bool(raw, 'over_18') ?? _bool(raw, 'over18') ?? false,
      isSpoiler: _bool(raw, 'spoiler') ?? false,
      isSaved: _bool(raw, 'saved') ?? false,
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

  Map<String, dynamic> _pageProps(Map<String, dynamic> extracted) {
    final props = extracted['props'] as Map<String, dynamic>?;
    if (props == null) return extracted;
    return props['pageProps'] as Map<String, dynamic>? ?? extracted;
  }

  VoteDirection _parseVote(dynamic likes) {
    if (likes == true) return VoteDirection.upvote;
    if (likes == false) return VoteDirection.downvote;
    return VoteDirection.none;
  }

  int? _int(Map<String, dynamic> map, String key) => map[key] as int?;
  bool? _bool(Map<String, dynamic> map, String key) => map[key] as bool?;
}

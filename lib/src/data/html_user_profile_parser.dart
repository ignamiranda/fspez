import '../domain/enums/vote_direction.dart';
import '../domain/models/comment.dart';
import '../domain/models/user_profile.dart';
import 'shreddit_json_extractor.dart';

class HtmlUserProfileParser {
  UserProfile parseProfile(String html, String username) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawUser = pageProps['user'] as Map<String, dynamic>? ??
        pageProps['profile'] as Map<String, dynamic>? ??
        {};

    final id = rawUser['id'] as String? ?? '';
    final name = rawUser['name'] as String? ?? username;
    final linkKarma =
        _int(rawUser, 'linkKarma') ?? _int(rawUser, 'link_karma') ?? 0;
    final commentKarma =
        _int(rawUser, 'commentKarma') ?? _int(rawUser, 'comment_karma') ?? 0;
    final createdUtc =
        _int(rawUser, 'createdUtc') ?? _int(rawUser, 'created_utc') ?? 0;
    final iconUrl =
        rawUser['iconUrl'] as String? ?? rawUser['icon_img'] as String?;
    final isGold =
        _bool(rawUser, 'isGold') ?? _bool(rawUser, 'is_gold') ?? false;
    final isMod = _bool(rawUser, 'isMod') ?? _bool(rawUser, 'is_mod') ?? false;

    return UserProfile(
      id: id,
      username: name,
      linkKarma: linkKarma,
      commentKarma: commentKarma,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      iconUrl: iconUrl,
      isGold: isGold,
      isMod: isMod,
    );
  }

  List<Comment> parseComments(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawComments = pageProps['comments'] as List<dynamic>? ?? [];
    return rawComments
        .whereType<Map<String, dynamic>>()
        .map(_commentFromRaw)
        .toList();
  }

  Comment _commentFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final body = raw['body'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final score = _int(raw, 'score') ?? 0;
    final createdUtc = _int(raw, 'createdUtc') ?? _int(raw, 'created_utc') ?? 0;
    final linkId = raw['linkId'] as String? ?? raw['link_id'] as String? ?? '';
    final parentId = raw['parentId'] as String? ?? raw['parent_id'] as String?;
    final depth = _int(raw, 'depth') ?? 0;

    return Comment(
      id: id,
      body: body,
      author: author,
      score: score,
      vote: _parseVote(raw['likes']),
      isSaved: _bool(raw, 'saved') ?? false,
      isSubmitter:
          _bool(raw, 'isSubmitter') ?? _bool(raw, 'is_submitter') ?? false,
      awardCount: _int(raw, 'totalAwardsReceived') ??
          _int(raw, 'total_awards_received') ??
          0,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      postId: linkId,
      parentId: parentId,
      depth: depth,
      replies: [],
      subreddit: raw['subreddit'] as String?,
      linkTitle: raw['linkTitle'] as String? ?? raw['link_title'] as String?,
      linkPermalink:
          raw['linkPermalink'] as String? ?? raw['link_permalink'] as String?,
    );
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

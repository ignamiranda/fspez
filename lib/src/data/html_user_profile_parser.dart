import '../domain/models/comment.dart';
import '../domain/models/user_profile.dart';
import 'html_parser_utils.dart';
import 'shreddit_json_extractor.dart';

class HtmlUserProfileParser {
  UserProfile parseProfile(String html, String username) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final rawUser = pp['user'] as Map<String, dynamic>? ??
        pp['profile'] as Map<String, dynamic>? ??
        {};

    final id = rawUser['id'] as String? ?? '';
    final name = rawUser['name'] as String? ?? username;
    final linkKarma =
        intOr(rawUser, 'linkKarma') ?? intOr(rawUser, 'link_karma') ?? 0;
    final commentKarma =
        intOr(rawUser, 'commentKarma') ?? intOr(rawUser, 'comment_karma') ?? 0;
    final createdUtc =
        intOr(rawUser, 'createdUtc') ?? intOr(rawUser, 'created_utc') ?? 0;
    final iconUrl =
        rawUser['iconUrl'] as String? ?? rawUser['icon_img'] as String?;
    final isGold =
        boolOr(rawUser, 'isGold') ?? boolOr(rawUser, 'is_gold') ?? false;
    final isMod =
        boolOr(rawUser, 'isMod') ?? boolOr(rawUser, 'is_mod') ?? false;

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
    final pp = pageProps(extracted);

    final rawComments = pp['comments'] as List<dynamic>? ?? [];
    return rawComments
        .whereType<Map<String, dynamic>>()
        .map(_commentFromRaw)
        .toList();
  }

  Comment _commentFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final body = raw['body'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final score = intOr(raw, 'score') ?? 0;
    final createdUtc =
        intOr(raw, 'createdUtc') ?? intOr(raw, 'created_utc') ?? 0;
    final linkId = raw['linkId'] as String? ?? raw['link_id'] as String? ?? '';
    final parentId = raw['parentId'] as String? ?? raw['parent_id'] as String?;
    final depth = intOr(raw, 'depth') ?? 0;

    return Comment(
      id: id,
      body: body,
      author: author,
      score: score,
      vote: parseVote(raw['likes']),
      isSaved: boolOr(raw, 'saved') ?? false,
      isSubmitter:
          boolOr(raw, 'isSubmitter') ?? boolOr(raw, 'is_submitter') ?? false,
      awardCount: intOr(raw, 'totalAwardsReceived') ??
          intOr(raw, 'total_awards_received') ??
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
}

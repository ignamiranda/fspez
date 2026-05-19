import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/enums/feed_sort.dart';
import '../domain/enums/vote_direction.dart';

class FeedParser {
  Feed parseFeed(
    Map<String, dynamic> data,
    FeedKind kind,
    FeedSort sort, {
    String? multiredditName,
  }) {
    final listing = data['data'] as Map<String, dynamic>;
    final children = listing['children'] as List<dynamic>;

    final posts = children
        .map((child) => parsePost(child['data'] as Map<String, dynamic>))
        .toList();

    return Feed(
      kind: kind,
      sort: sort,
      posts: posts,
      after: listing['after'] as String?,
      before: listing['before'] as String?,
      multiredditName: multiredditName,
    );
  }

  Post parsePost(Map<String, dynamic> data) {
    return Post(
      id: data['id'] as String,
      title: data['title'] as String? ?? '',
      selftext: data['selftext'] as String?,
      url: data['url'] as String?,
      thumbnailUrl: data['thumbnail'] as String?,
      type: parsePostType(data),
      author: data['author'] as String? ?? '[deleted]',
      subreddit: Subreddit(
        id: data['subreddit_id'] as String? ?? '',
        name: data['subreddit'] as String? ?? '',
        iconUrl: _subredditIcon(data),
      ),
      score: data['score'] as int? ?? 0,
      commentCount: data['num_comments'] as int? ?? 0,
      vote: parseVote(data['likes']),
      isNsfw: data['over_18'] as bool? ?? false,
      isSpoiler: data['spoiler'] as bool? ?? false,
      isSaved: data['saved'] as bool? ?? false,
      isStickied: data['stickied'] as bool? ?? false,
      isLocked: data['locked'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['created_utc'] as num).toInt() * 1000,
      ),
      permalink: data['permalink'] as String? ?? '',
      upvoteRatio: (data['upvote_ratio'] as num?)?.toDouble(),
    );
  }

  PostType parsePostType(Map<String, dynamic> data) {
    final hint = data['post_hint'] as String?;
    if (hint == 'image') return PostType.image;
    if (hint == 'link') return PostType.link;
    if (hint == 'hosted:video') return PostType.video;
    if (hint == 'rich:video') return PostType.video;
    if (data['is_gallery'] == true) return PostType.gallery;
    if (data['is_self'] == true) return PostType.self_;
    if (data['crosspost_parent'] != null) return PostType.crosspost;
    return PostType.link;
  }

  VoteDirection parseVote(dynamic likes) {
    if (likes == true) return VoteDirection.upvote;
    if (likes == false) return VoteDirection.downvote;
    return VoteDirection.none;
  }

  String? _subredditIcon(Map<String, dynamic> data) {
    final srDetail = data['sr_detail'] as Map<String, dynamic>?;
    if (srDetail == null) return null;
    final icon = srDetail['icon_img'] as String?;
    if (icon != null && icon.isNotEmpty) return _cleanUrl(icon);
    final communityIcon = srDetail['community_icon'] as String?;
    if (communityIcon != null && communityIcon.isNotEmpty) return _cleanUrl(communityIcon);
    return null;
  }

  String _cleanUrl(String url) {
    return url.replaceAll('&amp;', '&');
  }
}

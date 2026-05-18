import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/enums/feed_sort.dart';
import '../domain/enums/vote_direction.dart';
import 'reddit_client.dart';

class FeedRepository {
  final RedditClient _client;

  FeedRepository(this._client);

  Future<Feed> fetchHome({FeedSort sort = FeedSort.best, String? after}) {
    return _fetchFeed('/_api/home', sort, after, FeedKind.home);
  }

  Future<Feed> fetchPopular({String? after}) {
    return _fetchFeed('/r/popular', FeedSort.hot, after, FeedKind.popular);
  }

  Future<Feed> fetchAll({FeedSort sort = FeedSort.hot, String? after}) {
    return _fetchFeed('/r/all', sort, after, FeedKind.all_);
  }

  Future<Feed> fetchSubreddit(
    String subredditName, {
    FeedSort sort = FeedSort.hot,
    String? after,
  }) async {
    final path = '/r/$subredditName';
    final data = await _client.get(path, queryParams: {
      'sort': sort.name,
      if (after != null) 'after': after,
      'limit': '25',
    });

    return _parseFeed(data, FeedKind.home, sort);
  }

  Future<Feed> fetchMultireddit(
    String username,
    String multiredditName, {
    FeedSort sort = FeedSort.hot,
    String? after,
  }) async {
    final path = '/user/$username/m/$multiredditName';
    final data = await _client.get(path, queryParams: {
      'sort': sort.name,
      if (after != null) 'after': after,
      'limit': '25',
    });

    return _parseFeed(data, FeedKind.multireddit, sort,
        multiredditName: multiredditName);
  }

  Future<Feed> _fetchFeed(
    String path,
    FeedSort sort,
    String? after,
    FeedKind kind, {
    String? multiredditName,
  }) async {
    final data = await _client.get(path, queryParams: {
      'sort': sort.name,
      if (after != null) 'after': after,
      'limit': '25',
    });

    return _parseFeed(data, kind, sort, multiredditName: multiredditName);
  }

  Feed _parseFeed(
    Map<String, dynamic> data,
    FeedKind kind,
    FeedSort sort, {
    String? multiredditName,
  }) {
    final listing = data['data'] as Map<String, dynamic>;
    final children = listing['children'] as List<dynamic>;

    final posts = children
        .map((child) => _parsePost(child['data'] as Map<String, dynamic>))
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

  Post _parsePost(Map<String, dynamic> data) {
    return Post(
      id: data['id'] as String,
      title: data['title'] as String? ?? '',
      selftext: data['selftext'] as String?,
      url: data['url'] as String?,
      thumbnailUrl: data['thumbnail'] as String?,
      type: _parsePostType(data),
      author: data['author'] as String? ?? '[deleted]',
      subreddit: Subreddit(
        id: data['subreddit_id'] as String? ?? '',
        name: data['subreddit'] as String? ?? '',
      ),
      score: data['score'] as int? ?? 0,
      commentCount: data['num_comments'] as int? ?? 0,
      vote: _parseVote(data['likes']),
      isNsfw: data['over_18'] as bool? ?? false,
      isSpoiler: data['spoiler'] as bool? ?? false,
      isSaved: data['saved'] as bool? ?? false,
      isStickied: data['stickied'] as bool? ?? false,
      isLocked: data['locked'] as bool? ?? false,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((data['created_utc'] as num).toInt() * 1000),
      permalink: data['permalink'] as String? ?? '',
      upvoteRatio: (data['upvote_ratio'] as num?)?.toDouble(),
    );
  }

  PostType _parsePostType(Map<String, dynamic> data) {
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

  VoteDirection _parseVote(dynamic likes) {
    if (likes == true) return VoteDirection.upvote;
    if (likes == false) return VoteDirection.downvote;
    return VoteDirection.none;
  }
}



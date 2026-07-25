import '../domain/enums/vote_direction.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import 'shreddit_json_extractor.dart';

class HtmlSavedHiddenParser {
  List<Post> parseSaved(String html) {
    return _parseList(html, 'savedPosts');
  }

  List<Post> parseHidden(String html) {
    return _parseList(html, 'hiddenPosts');
  }

  String? parseAfter(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);
    return pageProps['after'] as String?;
  }

  List<Post> _parseList(String html, String key) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawPosts = pageProps[key] as List<dynamic>? ??
        pageProps['posts'] as List<dynamic>? ??
        [];

    return rawPosts
        .whereType<Map<String, dynamic>>()
        .map(_postFromRaw)
        .toList();
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

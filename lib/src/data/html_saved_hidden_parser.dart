import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import 'html_parser_utils.dart';
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
    final pp = pageProps(extracted);
    return pp['after'] as String?;
  }

  List<Post> _parseList(String html, String key) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final rawPosts =
        pp[key] as List<dynamic>? ?? pp['posts'] as List<dynamic>? ?? [];

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
}

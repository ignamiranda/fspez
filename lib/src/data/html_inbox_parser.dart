import '../domain/enums/vote_direction.dart';
import '../domain/models/inbox_feed.dart';
import '../domain/models/inbox_item.dart';
import 'shreddit_json_extractor.dart';

class HtmlInboxParser {
  InboxFeed parseInbox(String html, InboxTab tab) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawMessages = pageProps['messages'] as List<dynamic>?;
    final items = rawMessages
            ?.whereType<Map<String, dynamic>>()
            .map(_inboxItemFromRaw)
            .toList() ??
        [];

    final after = pageProps['after'] as String?;

    return InboxFeed(tab: tab, items: items, after: after);
  }

  InboxItem _inboxItemFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final subject = raw['subject'] as String? ?? '(no subject)';
    final body = raw['body'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final dest = raw['dest'] as String? ?? '';
    final createdUtc = _int(raw, 'createdUtc') ?? _int(raw, 'created_utc') ?? 0;
    final isNew = raw['new'] as bool? ?? false;
    final wasComment =
        (raw['wasComment'] as bool?) ?? (raw['was_comment'] as bool?) ?? false;
    final parentId = raw['parentId'] as String? ?? raw['parent_id'] as String?;
    final subreddit = raw['subreddit'] as String?;
    final distinguished = raw['distinguished'] as String?;
    final context = raw['context'] as String?;
    final firstMessageName = raw['firstMessageName'] as String? ??
        raw['first_message_name'] as String?;
    final score = _int(raw, 'score') ?? 0;
    final likes = raw['likes'];

    final replies = _parseReplies(raw);
    final createdAt = createdUtc > 0
        ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
        : DateTime.now();

    if (wasComment) {
      return CommentNotification(
        id: id,
        subject: subject,
        body: body,
        author: author,
        createdAt: createdAt,
        isNew: isNew,
        parentId: parentId,
        subreddit: subreddit,
        distinguished: distinguished,
        vote: _parseVote(likes),
        score: score,
        context: context,
        firstMessageName: firstMessageName,
        replies: replies,
      );
    }

    return DirectMessage(
      id: id,
      subject: subject,
      body: body,
      author: author,
      dest: dest,
      createdAt: createdAt,
      isNew: isNew,
      parentId: parentId,
      replies: replies,
    );
  }

  List<InboxItem> _parseReplies(Map<String, dynamic> raw) {
    final rawReplies = raw['replies'];
    if (rawReplies is List) {
      return rawReplies
          .whereType<Map<String, dynamic>>()
          .map(_inboxItemFromRaw)
          .toList();
    }
    return [];
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
}

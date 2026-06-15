import '../domain/models/inbox_item.dart';
import 'api_responses/api_responses.dart';
import 'parsers/shared_parsers.dart';

class InboxParser {
  List<InboxItem> parseMessages(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't4' || child['kind'] == 't1')
        .map((child) => _toDomain(
            ApiMessage.fromJson(child['data'] as Map<String, dynamic>)))
        .toList();
  }

  InboxItem _toDomain(ApiMessage api) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(api.createdUtc * 1000);
    final replies = api.replies.isEmpty
        ? <InboxItem>[]
        : api.replies.map(_toDomain).toList();

    if (api.wasComment) {
      return CommentNotification(
        id: api.id,
        subject: api.subject,
        body: api.body,
        author: api.author,
        createdAt: createdAt,
        isNew: api.isNew,
        parentId: api.parentId,
        subreddit: api.subreddit,
        distinguished: api.distinguished,
        vote: parseVoteDirection(api.likes),
        score: api.score,
        context: api.context,
        firstMessageName: api.firstMessageName,
        replies: replies,
      );
    }

    return DirectMessage(
      id: api.id,
      subject: api.subject,
      body: api.body,
      author: api.author,
      dest: api.dest,
      createdAt: createdAt,
      isNew: api.isNew,
      parentId: api.parentId,
      replies: replies,
    );
  }
}

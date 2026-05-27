import '../domain/models/message.dart';
import 'api_responses.dart';
import 'parsers/shared_parsers.dart';

class InboxParser {
  List<Message> parseMessages(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't4' || child['kind'] == 't1')
        .map((child) => _toDomain(
            ApiMessage.fromJson(child['data'] as Map<String, dynamic>)))
        .toList();
  }

  Message _toDomain(ApiMessage api) {
    return Message(
      id: api.id,
      subject: api.subject,
      body: api.body,
      author: api.author,
      dest: api.dest,
      createdAt: DateTime.fromMillisecondsSinceEpoch(api.createdUtc * 1000),
      isNew: api.isNew,
      isComment: api.wasComment,
      parentId: api.parentId,
      replies: api.replies.map(_toDomain).toList(),
      subreddit: api.subreddit,
      distinguished: api.distinguished,
      vote: parseVoteDirection(api.likes),
      score: api.score,
      context: api.context,
      firstMessageName: api.firstMessageName,
    );
  }
}

import '../domain/models/message.dart';
import 'parsers/shared_parsers.dart';

class InboxParser {
  List<Message> parseMessages(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't4' || child['kind'] == 't1')
        .map((child) => _parseSingle(child['data'] as Map<String, dynamic>))
        .toList();
  }

  Message _parseSingle(Map<String, dynamic> data) {
    final repliesRaw = data['replies'];
    List<Message> replies;
    if (repliesRaw is Map<String, dynamic> &&
        repliesRaw['kind'] == 'Listing') {
      final children =
          (repliesRaw['data'] as Map<String, dynamic>)['children']
              as List<dynamic>;
      replies = parseMessages(children);
    } else {
      replies = [];
    }

    return Message(
      id: data['id'] as String? ?? '',
      subject: data['subject'] as String? ?? '(no subject)',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '[deleted]',
      dest: data['dest'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['created_utc'] as num).toInt() * 1000,
      ),
      isNew: data['new'] as bool? ?? false,
      isComment: data['was_comment'] as bool? ?? false,
      parentId: data['parent_id'] as String?,
      replies: replies,
      subreddit: data['subreddit'] as String?,
      distinguished: data['distinguished'] as String?,
      vote: parseVoteDirection(data['likes']),
      score: data['score'] as int? ?? 0,
      context: data['context'] as String?,
      firstMessageName: data['first_message_name'] as String?,
    );
  }
}

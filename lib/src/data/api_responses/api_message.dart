import '../../domain/models/inbox_item.dart';
import '../post_mapping.dart' as post_mapping;

class ApiMessage {
  final String id;
  final String subject;
  final String body;
  final String author;
  final String dest;
  final int createdUtc;
  final bool isNew;
  final bool wasComment;
  final String? parentId;
  final String? subreddit;
  final String? distinguished;
  final dynamic likes;
  final int score;
  final String? context;
  final String? firstMessageName;
  final List<ApiMessage> replies;

  ApiMessage({
    required this.id,
    required this.subject,
    required this.body,
    required this.author,
    required this.dest,
    required this.createdUtc,
    required this.isNew,
    required this.wasComment,
    this.parentId,
    this.subreddit,
    this.distinguished,
    this.likes,
    required this.score,
    this.context,
    this.firstMessageName,
    required this.replies,
  });

  factory ApiMessage.fromJson(Map<String, dynamic> data) {
    final repliesRaw = data['replies'];
    List<ApiMessage> replies;
    if (repliesRaw is Map<String, dynamic> && repliesRaw['kind'] == 'Listing') {
      final children = (repliesRaw['data'] as Map<String, dynamic>)['children']
          as List<dynamic>;
      replies = children
          .whereType<Map<String, dynamic>>()
          .where((c) => c['kind'] == 't4' || c['kind'] == 't1')
          .map((c) => ApiMessage.fromJson(c['data'] as Map<String, dynamic>))
          .toList();
    } else {
      replies = [];
    }

    return ApiMessage(
      id: data['id'] as String? ?? '',
      subject: data['subject'] as String? ?? '(no subject)',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '[deleted]',
      dest: data['dest'] as String? ?? '',
      createdUtc: (data['created_utc'] as num).toInt(),
      isNew: data['new'] as bool? ?? false,
      wasComment: data['was_comment'] as bool? ?? false,
      parentId: data['parent_id'] as String?,
      subreddit: data['subreddit'] as String?,
      distinguished: data['distinguished'] as String?,
      likes: data['likes'],
      score: data['score'] as int? ?? 0,
      context: data['context'] as String?,
      firstMessageName: data['first_message_name'] as String?,
      replies: replies,
    );
  }

  InboxItem toDomain() {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000);
    final replyList = replies.isEmpty
        ? <InboxItem>[]
        : replies.map((r) => r.toDomain()).toList();

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
        vote: post_mapping.parseVoteDirection(likes),
        score: score,
        context: context,
        firstMessageName: firstMessageName,
        replies: replyList,
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
      replies: replyList,
    );
  }
}

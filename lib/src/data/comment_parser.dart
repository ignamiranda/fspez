import '../domain/models/comment.dart';
import 'parsers/shared_parsers.dart';

class CommentParser {
  List<Comment> parseComments(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't1')
        .map((child) => _parseSingle(child['data'] as Map<String, dynamic>))
        .toList();
  }

  Comment _parseSingle(Map<String, dynamic> data) {
    final repliesRaw = data['replies'];
    List<Comment> replies;
    if (repliesRaw is Map<String, dynamic> &&
        repliesRaw['kind'] == 'Listing') {
      final children =
          (repliesRaw['data'] as Map<String, dynamic>)['children']
              as List<dynamic>;
      replies = parseComments(children);
    } else {
      replies = [];
    }

    return Comment(
      id: data['id'] as String? ?? '',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '[deleted]',
      score: data['score'] as int? ?? 0,
      vote: parseVoteDirection(data['likes']),
      isSaved: data['saved'] as bool? ?? false,
      isSubmitter: data['is_submitter'] as bool? ?? false,
      isModerator: data['distinguished'] == 'moderator',
      isStickied: data['stickied'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['created_utc'] as num).toInt() * 1000,
      ),
      postId: data['link_id'] as String? ?? '',
      parentId: data['parent_id'] as String?,
      depth: data['depth'] as int? ?? 0,
      replies: replies,
      isCollapsed: data['collapsed'] as bool? ?? false,
    );
  }
}

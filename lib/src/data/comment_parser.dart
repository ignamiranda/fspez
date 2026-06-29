import '../domain/models/comment.dart';
import 'api_responses/api_responses.dart';

class CommentParser {
  List<Comment> parseComments(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't1')
        .map((child) => _toDomain(
            ApiComment.fromJson(child['data'] as Map<String, dynamic>)))
        .toList();
  }

  Comment _toDomain(ApiComment api) {
    return api.toDomain();
  }
}

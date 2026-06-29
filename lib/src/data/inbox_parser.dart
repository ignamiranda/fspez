import '../domain/models/inbox_item.dart';
import 'api_responses/api_responses.dart';

class InboxParser {
  List<InboxItem> parseMessages(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't4' || child['kind'] == 't1')
        .map((child) =>
            ApiMessage.fromJson(child['data'] as Map<String, dynamic>).toDomain())
        .toList();
  }
}

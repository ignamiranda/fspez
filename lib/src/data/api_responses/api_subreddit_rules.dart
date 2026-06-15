import '../../domain/models/subreddit_rule.dart';
import 'api_subreddit_rule.dart';

class ApiSubredditRules {
  final List<ApiSubredditRule> rules;

  const ApiSubredditRules({required this.rules});

  factory ApiSubredditRules.fromJson(Map<String, dynamic> data) {
    final rules = (data['rules'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ApiSubredditRule.fromJson)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return ApiSubredditRules(rules: rules);
  }

  List<SubredditRule> toDomain() =>
      rules.map((rule) => rule.toDomain()).toList();
}

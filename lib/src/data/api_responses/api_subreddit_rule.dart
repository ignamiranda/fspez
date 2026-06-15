import '../../domain/models/subreddit_rule.dart';

class ApiSubredditRule {
  final String shortName;
  final String description;
  final String kind;
  final String? violationReason;
  final int priority;

  const ApiSubredditRule({
    required this.shortName,
    required this.description,
    required this.kind,
    this.violationReason,
    required this.priority,
  });

  factory ApiSubredditRule.fromJson(Map<String, dynamic> data) {
    return ApiSubredditRule(
      shortName: data['short_name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      kind: data['kind'] as String? ?? 'all',
      violationReason: data['violation_reason'] as String?,
      priority: (data['priority'] as num?)?.toInt() ?? 0,
    );
  }

  SubredditRule toDomain() {
    return SubredditRule(
      shortName: shortName,
      description: description,
      kind: kind,
      violationReason: violationReason,
      priority: priority,
    );
  }
}

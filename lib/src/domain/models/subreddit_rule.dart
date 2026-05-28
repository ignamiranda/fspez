import 'package:equatable/equatable.dart';

class SubredditRule extends Equatable {
  final String shortName;
  final String description;
  final String kind;
  final String? violationReason;
  final int priority;

  const SubredditRule({
    required this.shortName,
    required this.description,
    required this.kind,
    this.violationReason,
    required this.priority,
  });

  @override
  List<Object?> get props => [
        shortName,
        description,
        kind,
        violationReason,
        priority,
      ];
}

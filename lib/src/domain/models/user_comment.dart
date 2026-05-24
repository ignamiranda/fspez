import 'package:equatable/equatable.dart';
import '../../domain/enums/vote_direction.dart';

class UserComment with EquatableMixin {
  final String id;
  final String body;
  final String author;
  final int score;
  final VoteDirection vote;
  final DateTime createdAt;
  final String subreddit;
  final String linkTitle;
  final String linkPermalink;
  final String postId;

  String get fullname => 't1_$id';

  const UserComment({
    required this.id,
    required this.body,
    required this.author,
    this.score = 0,
    this.vote = VoteDirection.none,
    required this.createdAt,
    required this.subreddit,
    required this.linkTitle,
    required this.linkPermalink,
    required this.postId,
  });

  @override
  List<Object?> get props => [
        id,
        body,
        author,
        score,
        vote,
        createdAt,
        subreddit,
        linkTitle,
        linkPermalink,
        postId,
      ];
}

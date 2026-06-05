import 'package:equatable/equatable.dart';
import '../enums/vote_direction.dart';

sealed class InboxItem {
  String get id;
  String get subject;
  String get body;
  String get author;
  DateTime get createdAt;
  bool get isNew;
  String get fullname;
  String? get parentId;
  List<InboxItem> get replies;

  InboxItem copyWith({bool? isNew});

  const InboxItem();
}

class DirectMessage extends InboxItem with EquatableMixin {
  @override
  final String id;
  @override
  final String subject;
  @override
  final String body;
  @override
  final String author;
  final String dest;
  @override
  final DateTime createdAt;
  @override
  final bool isNew;
  @override
  final String? parentId;
  @override
  final List<InboxItem> replies;

  @override
  String get fullname => 't4_$id';

  const DirectMessage({
    required this.id,
    required this.subject,
    required this.body,
    required this.author,
    required this.dest,
    required this.createdAt,
    this.isNew = false,
    this.parentId,
    this.replies = const [],
  });

  @override
  DirectMessage copyWith({bool? isNew}) {
    return DirectMessage(
      id: id,
      subject: subject,
      body: body,
      author: author,
      dest: dest,
      createdAt: createdAt,
      isNew: isNew ?? this.isNew,
      parentId: parentId,
      replies: replies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subject,
        body,
        author,
        dest,
        createdAt,
        isNew,
        parentId,
        replies,
      ];
}

class CommentNotification extends InboxItem with EquatableMixin {
  @override
  final String id;
  @override
  final String subject;
  @override
  final String body;
  @override
  final String author;
  @override
  final DateTime createdAt;
  @override
  final bool isNew;
  @override
  final String? parentId;
  final String? subreddit;
  final String? distinguished;
  final VoteDirection vote;
  final int score;
  final String? context;
  final String? firstMessageName;
  @override
  final List<InboxItem> replies;

  @override
  String get fullname => 't1_$id';

  const CommentNotification({
    required this.id,
    required this.subject,
    required this.body,
    required this.author,
    required this.createdAt,
    this.isNew = false,
    this.parentId,
    this.subreddit,
    this.distinguished,
    this.vote = VoteDirection.none,
    this.score = 0,
    this.context,
    this.firstMessageName,
    this.replies = const [],
  });

  @override
  CommentNotification copyWith({bool? isNew}) {
    return CommentNotification(
      id: id,
      subject: subject,
      body: body,
      author: author,
      createdAt: createdAt,
      isNew: isNew ?? this.isNew,
      parentId: parentId,
      subreddit: subreddit,
      distinguished: distinguished,
      vote: vote,
      score: score,
      context: context,
      firstMessageName: firstMessageName,
      replies: replies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subject,
        body,
        author,
        createdAt,
        isNew,
        parentId,
        subreddit,
        distinguished,
        vote,
        score,
        context,
        firstMessageName,
        replies,
      ];
}

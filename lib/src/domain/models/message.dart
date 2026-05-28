import 'package:equatable/equatable.dart';
import '../../domain/enums/vote_direction.dart';

class Message with EquatableMixin {
  final String id;
  final String subject;
  final String body;
  final String author;
  final String dest;
  final DateTime createdAt;
  final bool isNew;
  final bool isComment;
  final String? parentId;
  final List<Message> replies;
  final String? subreddit;
  final String? distinguished;
  final VoteDirection vote;
  final int score;
  final String? context;
  final String? firstMessageName;

  String get fullname => 't4_$id';

  const Message({
    required this.id,
    required this.subject,
    required this.body,
    required this.author,
    required this.dest,
    required this.createdAt,
    this.isNew = false,
    this.isComment = false,
    this.parentId,
    this.replies = const [],
    this.subreddit,
    this.distinguished,
    this.vote = VoteDirection.none,
    this.score = 0,
    this.context,
    this.firstMessageName,
  });

  Message copyWith({
    String? id,
    String? subject,
    String? body,
    String? author,
    String? dest,
    DateTime? createdAt,
    bool? isNew,
    bool? isComment,
    String? parentId,
    List<Message>? replies,
    String? subreddit,
    String? distinguished,
    VoteDirection? vote,
    int? score,
    String? context,
    String? firstMessageName,
  }) {
    return Message(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      author: author ?? this.author,
      dest: dest ?? this.dest,
      createdAt: createdAt ?? this.createdAt,
      isNew: isNew ?? this.isNew,
      isComment: isComment ?? this.isComment,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
      subreddit: subreddit ?? this.subreddit,
      distinguished: distinguished ?? this.distinguished,
      vote: vote ?? this.vote,
      score: score ?? this.score,
      context: context ?? this.context,
      firstMessageName: firstMessageName ?? this.firstMessageName,
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
        isComment,
        parentId,
        replies,
        subreddit,
        distinguished,
        vote,
        score,
        context,
        firstMessageName,
      ];
}

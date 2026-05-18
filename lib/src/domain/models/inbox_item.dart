import 'package:equatable/equatable.dart';

enum InboxItemType { commentReply, postReply, usernameMention, privateMessage }

class InboxItem with EquatableMixin {
  final String id;
  final InboxItemType type;
  final String author;
  final String body;
  final String subject;
  final String? contextUrl;
  final bool isUnread;
  final DateTime createdAt;

  const InboxItem({
    required this.id,
    required this.type,
    required this.author,
    required this.body,
    required this.subject,
    this.contextUrl,
    this.isUnread = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        author,
        body,
        subject,
        contextUrl,
        isUnread,
        createdAt,
      ];
}

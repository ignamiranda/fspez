import 'package:equatable/equatable.dart';
import 'message.dart';

enum InboxTab { inbox, unread, sent }

class MessageFeed with EquatableMixin {
  final InboxTab tab;
  final List<Message> messages;
  final String? after;
  final String? before;

  const MessageFeed({
    required this.tab,
    this.messages = const [],
    this.after,
    this.before,
  });

  bool get hasMorePages => after != null;

  @override
  List<Object?> get props => [tab, messages, after, before];
}

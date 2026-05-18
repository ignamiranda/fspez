import 'package:equatable/equatable.dart';

class ChatMessage with EquatableMixin {
  final String id;
  final String chatId;
  final String author;
  final String body;
  final bool isOwn;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.author,
    required this.body,
    this.isOwn = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, chatId, author, body, isOwn, createdAt];
}

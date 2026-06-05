import 'package:equatable/equatable.dart';
import 'inbox_item.dart';

enum InboxTab { all, unread, sent }

class InboxFeed with EquatableMixin {
  final InboxTab tab;
  final List<InboxItem> items;
  final String? after;
  final String? before;

  const InboxFeed({
    required this.tab,
    this.items = const [],
    this.after,
    this.before,
  });

  bool get hasMorePages => after != null;

  @override
  List<Object?> get props => [tab, items, after, before];
}

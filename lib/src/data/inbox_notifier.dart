import 'package:equatable/equatable.dart';
import '../domain/models/message.dart';
import '../domain/models/message_feed.dart';
import '../domain/models/account.dart';
import 'inbox_repository.dart';
import 'cursor_paginated_notifier.dart';

class InboxState with EquatableMixin {
  final InboxTab tab;
  final List<Message> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  const InboxState({
    this.tab = InboxTab.inbox,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = false,
  });

  InboxState copyWith({
    InboxTab? tab,
    List<Message>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    bool clearError = false,
  }) {
    return InboxState(
      tab: tab ?? this.tab,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props =>
      [tab, messages, isLoading, isLoadingMore, error, hasMore];
}

class InboxNotifier
    extends CursorPaginatedNotifier<InboxState, MessageFeed> {
  final InboxRepository _repository;
  final Account? _account;

  InboxNotifier(this._repository, this._account, {bool autoLoad = true})
      : super(const InboxState(isLoading: true), autoLoad: false) {
    if (autoLoad) {
      Future.microtask(() => loadTab(InboxTab.inbox));
    }
  }

  Future<void> loadTab(InboxTab tab) async {
    state = state.copyWith(tab: tab, isLoading: true, clearError: true);
    after = null;
    try {
      final feed = await _fetch(tab, after: null);
      after = feed.after;
      state = state.copyWith(
        messages: feed.messages,
        isLoading: false,
        hasMore: feed.hasMorePages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<MessageFeed> _fetch(InboxTab tab, {String? after}) {
    final cookie = _account?.sessionCookie;
    return switch (tab) {
      InboxTab.inbox => _repository.fetchInbox(after: after, sessionCookie: cookie),
      InboxTab.unread => _repository.fetchUnread(after: after, sessionCookie: cookie),
      InboxTab.sent => _repository.fetchSent(after: after, sessionCookie: cookie),
    };
  }

  @override
  Future<MessageFeed> fetchPage({String? after}) =>
      _fetch(state.tab, after: after);

  @override
  String? extractAfter(MessageFeed page) => page.after;

  @override
  InboxState buildLoadingState(InboxState current) =>
      InboxState(isLoading: true, tab: current.tab);

  @override
  InboxState buildSuccessState(MessageFeed page) => InboxState(
        tab: page.tab,
        messages: page.messages,
        isLoading: false,
        hasMore: page.hasMorePages,
      );

  @override
  InboxState buildLoadingMoreState(InboxState current) =>
      current.copyWith(isLoadingMore: true);

  @override
  InboxState buildAppendedState(InboxState current, MessageFeed page) =>
      current.copyWith(
        messages: [...current.messages, ...page.messages],
        isLoadingMore: false,
        hasMore: page.hasMorePages,
      );

  @override
  InboxState buildErrorState(String error) =>
      InboxState(isLoading: false, error: error);

  @override
  InboxState buildErrorWithState(InboxState current, String error) =>
      current.copyWith(isLoadingMore: false, error: error);

  @override
  bool getIsLoadingMore(InboxState state) => state.isLoadingMore;

  @override
  bool getHasMore(InboxState state) => state.hasMore;
}

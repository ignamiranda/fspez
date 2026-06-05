import 'package:equatable/equatable.dart';
import '../domain/models/inbox_item.dart';
import '../domain/models/inbox_feed.dart';
import '../domain/models/account.dart';
import 'inbox_repository.dart';
import 'cursor_paginated_notifier.dart';

class InboxState with EquatableMixin {
  final InboxTab tab;
  final List<InboxItem> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int unreadCount;

  const InboxState({
    this.tab = InboxTab.all,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = false,
    this.unreadCount = 0,
  });

  InboxState copyWith({
    InboxTab? tab,
    List<InboxItem>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? unreadCount,
    bool clearError = false,
  }) {
    return InboxState(
      tab: tab ?? this.tab,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props =>
      [tab, messages, isLoading, isLoadingMore, error, hasMore, unreadCount];
}

class InboxNotifier extends CursorPaginatedNotifier<InboxState, InboxFeed> {
  final InboxRepository _repository;
  final Account? _account;

  InboxNotifier(this._repository, this._account, {bool autoLoad = true})
      : super(const InboxState(isLoading: true), autoLoad: false) {
    if (autoLoad) {
      Future.microtask(() async {
        await loadTab(InboxTab.all);
        await refreshUnreadCount();
      });
    }
  }

  Future<void> loadTab(InboxTab tab) async {
    state = state.copyWith(tab: tab, isLoading: true, clearError: true);
    after = null;
    try {
      final feed = await _fetch(tab, after: null);
      after = feed.after;
      state = state.copyWith(
        messages: feed.items,
        isLoading: false,
        hasMore: feed.hasMorePages,
        unreadCount: tab == InboxTab.unread ? feed.items.length : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<InboxFeed> _fetch(InboxTab tab, {String? after}) {
    final cookie = _account?.sessionCookie;
    return switch (tab) {
      InboxTab.all =>
        _repository.fetchInbox(after: after, sessionCookie: cookie),
      InboxTab.unread =>
        _repository.fetchUnread(after: after, sessionCookie: cookie),
      InboxTab.sent =>
        _repository.fetchSent(after: after, sessionCookie: cookie),
    };
  }

  Future<void> refreshUnreadCount() async {
    final cookie = _account?.sessionCookie;
    if (cookie == null) {
      state = state.copyWith(unreadCount: 0);
      return;
    }

    try {
      final feed = await _repository.fetchUnread(sessionCookie: cookie);
      state = state.copyWith(unreadCount: feed.items.length);
    } catch (_) {
      // Keep the last known badge count; inbox loading errors are shown in-tab.
    }
  }

  Future<void> markAsRead(InboxItem message) async {
    final cookie = _account?.sessionCookie;
    if (cookie == null || !message.isNew) return;

    final previousState = state;
    final updatedMessages = state.messages
        .where((m) => state.tab != InboxTab.unread || m.id != message.id)
        .map((m) => m.id == message.id ? m.copyWith(isNew: false) : m)
        .toList();

    state = state.copyWith(
      messages: updatedMessages,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    try {
      await _repository.markAsRead(message.fullname, cookie);
    } catch (_) {
      state = previousState;
      await refresh();
      await refreshUnreadCount();
      rethrow;
    }
  }

  @override
  Future<InboxFeed> fetchPage({String? after}) =>
      _fetch(state.tab, after: after);

  @override
  String? extractAfter(InboxFeed page) => page.after;

  @override
  InboxState buildLoadingState(InboxState current) => InboxState(
        isLoading: true,
        tab: current.tab,
        unreadCount: current.unreadCount,
      );

  @override
  InboxState buildSuccessState(InboxFeed page) => InboxState(
        tab: page.tab,
        messages: page.items,
        isLoading: false,
        hasMore: page.hasMorePages,
        unreadCount: page.tab == InboxTab.unread
            ? page.items.length
            : state.unreadCount,
      );

  @override
  InboxState buildLoadingMoreState(InboxState current) =>
      current.copyWith(isLoadingMore: true);

  @override
  InboxState buildAppendedState(InboxState current, InboxFeed page) =>
      current.copyWith(
        messages: [...current.messages, ...page.items],
        isLoadingMore: false,
        hasMore: page.hasMorePages,
      );

  @override
  InboxState buildErrorState(String error) => InboxState(
        isLoading: false,
        error: error,
        unreadCount: state.unreadCount,
      );

  @override
  InboxState buildErrorWithState(InboxState current, String error) =>
      current.copyWith(isLoadingMore: false, error: error);

  @override
  bool getIsLoadingMore(InboxState state) => state.isLoadingMore;

  @override
  bool getHasMore(InboxState state) => state.hasMore;
}

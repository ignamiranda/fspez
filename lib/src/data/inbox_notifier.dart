import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/inbox_item.dart';
import '../domain/models/inbox_feed.dart';
import '../domain/models/account.dart';
import 'inbox_repository.dart';
import 'paginated_notifier.dart';

class InboxState with Equatable {
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

class InboxNotifier extends StateNotifier<InboxState> {
  final InboxRepository _repository;
  final Account? _account;
  PaginatedNotifier<InboxItem>? _paginated;

  InboxNotifier(this._repository, this._account, {bool autoLoad = true})
      : super(const InboxState(isLoading: true)) {
    if (autoLoad) {
      Future.microtask(() async {
        await loadTab(InboxTab.all);
        await refreshUnreadCount();
      });
    }
  }

  /// Fetches a page from the appropriate inbox tab endpoint.
  Future<PaginatedResult<InboxItem>> _fetchPage(InboxTab tab,
      {String? after}) async {
    final cookie = _account?.sessionCookie;
    final feed = await switch (tab) {
      InboxTab.all =>
        _repository.fetchInbox(after: after, sessionCookie: cookie),
      InboxTab.unread =>
        _repository.fetchUnread(after: after, sessionCookie: cookie),
      InboxTab.sent =>
        _repository.fetchSent(after: after, sessionCookie: cookie),
    };
    return PaginatedResult<InboxItem>(
      items: feed.items,
      after: feed.after,
      hasMore: feed.hasMorePages,
    );
  }

  /// Syncs InboxState from the internal PaginatedNotifier's state.
  void _syncFromPaginated({int? unreadCount}) {
    if (_paginated == null) return;
    final ps = _paginated!.state;
    state = InboxState(
      tab: state.tab,
      messages: ps.items,
      isLoading: ps.isLoading,
      isLoadingMore: ps.isLoadingMore,
      error: ps.error,
      hasMore: ps.hasMore,
      unreadCount: unreadCount ?? state.unreadCount,
    );
  }

  Future<void> loadTab(InboxTab tab) async {
    state = state.copyWith(tab: tab, isLoading: true, clearError: true);
    _paginated = PaginatedNotifier<InboxItem>(
      fetchPage: ({after}) => _fetchPage(tab, after: after),
      autoLoad: false,
    );
    try {
      await _paginated!.loadInitial();
      _syncFromPaginated(
        unreadCount:
            tab == InboxTab.unread ? _paginated!.state.items.length : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (_paginated == null) return;
    await _paginated!.loadMore();
    _syncFromPaginated();
  }

  Future<void> refresh() => loadTab(state.tab);

  Future<void> refreshUnreadCount() async {
    final cookie = _account?.sessionCookie;
    if (cookie == null) {
      state = state.copyWith(unreadCount: 0);
      return;
    }

    try {
      final feed = await _repository.fetchUnread(sessionCookie: cookie);
      state = state.copyWith(unreadCount: feed.items.length);
    } catch (e) {
      debugPrint('InboxNotifier.refreshUnreadCount failed: $e');
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
    } catch (e) {
      debugPrint('InboxNotifier.markAsRead failed: $e');
      state = previousState;
      await refresh();
      await refreshUnreadCount();
      rethrow;
    }
  }
}

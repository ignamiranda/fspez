import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/inbox_item.dart';
import '../domain/models/inbox_feed.dart';
import '../domain/models/account.dart';
import 'inbox_repository.dart';
import 'paginated_notifier.dart';
import 'paginated_list_state.dart';

class InboxState with Equatable {
  final InboxTab tab;
  final int unreadCount;
  final PaginatedListState<InboxItem> page;

  const InboxState({
    this.tab = InboxTab.all,
    this.unreadCount = 0,
    this.page = const PaginatedListState(isLoading: true),
  });

  /// Convenience: delegates to [page] fields so consumers don't chase the
  /// inner state object.
  List<InboxItem> get messages => page.items;
  bool get isLoading => page.isLoading;
  bool get isLoadingMore => page.isLoadingMore;
  String? get error => page.error;
  bool get hasMore => page.hasMore;

  InboxState copyWith({
    InboxTab? tab,
    int? unreadCount,
    PaginatedListState<InboxItem>? page,
    bool clearError = false,
  }) {
    return InboxState(
      tab: tab ?? this.tab,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ??
          (clearError ? this.page.copyWith(clearError: true) : this.page),
    );
  }

  @override
  List<Object?> get props => [tab, unreadCount, page];
}

class InboxNotifier extends StateNotifier<InboxState> {
  final InboxRepository _repository;
  final Account? _account;
  PaginatedNotifier<InboxItem>? _paginated;

  InboxNotifier(this._repository, this._account, {bool autoLoad = true})
      : super(const InboxState()) {
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

  Future<void> loadTab(InboxTab tab) async {
    state = state.copyWith(
      tab: tab,
      page: const PaginatedListState(isLoading: true),
    );
    _paginated = PaginatedNotifier<InboxItem>(
      fetchPage: ({after}) => _fetchPage(tab, after: after),
      autoLoad: false,
    );
    try {
      await _paginated!.loadInitial();
      state = state.copyWith(
        page: _paginated!.state,
        unreadCount:
            tab == InboxTab.unread ? _paginated!.state.items.length : null,
      );
    } catch (e) {
      state = state.copyWith(
        page: PaginatedListState<InboxItem>(error: e.toString()),
      );
    }
  }

  Future<void> loadMore() async {
    if (_paginated == null) return;
    await _paginated!.loadMore();
    state = state.copyWith(page: _paginated!.state);
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
      page: state.page.copyWith(items: updatedMessages),
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

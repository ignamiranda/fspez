import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../domain/models/message.dart';
import '../domain/models/message_feed.dart';
import '../domain/models/account.dart';
import 'inbox_repository.dart';

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

class InboxNotifier extends StateNotifier<InboxState> {
  final InboxRepository _repository;
  final Account? _account;
  final ScrollController scrollController = ScrollController();

  String? _after;

  InboxNotifier(this._repository, this._account, {bool autoLoad = true})
      : super(const InboxState(isLoading: true)) {
    scrollController.addListener(_onScroll);
    if (autoLoad) {
      Future.microtask(() => loadTab(InboxTab.inbox));
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  Future<void> loadTab(InboxTab tab) async {
    state = state.copyWith(tab: tab, isLoading: true, clearError: true);
    _after = null;
    try {
      final feed = await _fetch(tab);
      _after = feed.after;
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

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final feed = await _fetch(state.tab, after: _after);
      _after = feed.after;
      state = state.copyWith(
        messages: [...state.messages, ...feed.messages],
        isLoadingMore: false,
        hasMore: feed.hasMorePages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadTab(state.tab);

  Future<MessageFeed> _fetch(InboxTab tab, {String? after}) {
    final cookie = _account?.sessionCookie;
    return switch (tab) {
      InboxTab.inbox => _repository.fetchInbox(after: after, sessionCookie: cookie),
      InboxTab.unread => _repository.fetchUnread(after: after, sessionCookie: cookie),
      InboxTab.sent => _repository.fetchSent(after: after, sessionCookie: cookie),
    };
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}

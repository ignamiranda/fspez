import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class CursorPaginatedNotifier<T, TPage>
    extends StateNotifier<T> {
  final ScrollController scrollController = ScrollController();
  String? after;

  CursorPaginatedNotifier(T initialState, {bool autoLoad = true})
      : super(initialState) {
    scrollController.addListener(_onScroll);
    if (autoLoad) {
      Future.microtask(() => loadInitial());
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  Future<void> loadInitial() async {
    state = buildLoadingState(state);
    after = null;
    try {
      final page = await fetchPage(after: null);
      after = extractAfter(page);
      state = buildSuccessState(page);
    } catch (e) {
      state = buildErrorState(e.toString());
    }
  }

  Future<void> loadMore() async {
    if (getIsLoadingMore(state) || !getHasMore(state)) return;
    state = buildLoadingMoreState(state);
    try {
      final page = await fetchPage(after: after);
      after = extractAfter(page);
      state = buildAppendedState(state, page);
    } catch (e) {
      state = buildErrorWithState(state, e.toString());
    }
  }

  void refresh() => loadInitial();

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  Future<TPage> fetchPage({String? after});
  String? extractAfter(TPage page);

  T buildLoadingState(T current);
  T buildSuccessState(TPage page);
  T buildLoadingMoreState(T current);
  T buildAppendedState(T current, TPage page);
  T buildErrorState(String error);
  T buildErrorWithState(T current, String error);

  bool getIsLoadingMore(T state);
  bool getHasMore(T state);
}

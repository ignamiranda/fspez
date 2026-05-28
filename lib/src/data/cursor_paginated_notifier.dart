import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class CursorPaginatedNotifier<T, TPage>
    extends StateNotifier<T> {
  String? after;

  CursorPaginatedNotifier(T initialState, {bool autoLoad = true})
      : super(initialState) {
    if (autoLoad) {
      Future.microtask(() => loadInitial());
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

  Future<void> refresh() => loadInitial();

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

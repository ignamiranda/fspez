import 'package:equatable/equatable.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/account.dart';
import '../domain/enums/feed_sort.dart';
import 'feed_repository.dart';
import 'cursor_paginated_notifier.dart';

class FeedPageState with EquatableMixin {
  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  const FeedPageState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [posts, isLoading, isLoadingMore, error, hasMore];
}

class FeedPageConfig with EquatableMixin {
  final FeedPageKind kind;
  final FeedSort sort;
  final String? identifier;

  const FeedPageConfig({
    required this.kind,
    this.sort = FeedSort.hot,
    this.identifier,
  });

  const FeedPageConfig.home({FeedSort sort = FeedSort.hot})
      : this(kind: FeedPageKind.home, sort: sort);

  const FeedPageConfig.popular()
      : this(kind: FeedPageKind.popular);

  const FeedPageConfig.popularAll({FeedSort sort = FeedSort.hot})
      : this(kind: FeedPageKind.popularAll, sort: sort);

  const FeedPageConfig.saved()
      : this(kind: FeedPageKind.saved, sort: FeedSort.new_);

  const FeedPageConfig.search(String query)
      : this(kind: FeedPageKind.search, sort: FeedSort.new_, identifier: query);

  const FeedPageConfig.subreddit(String name, {FeedSort sort = FeedSort.hot})
      : this(kind: FeedPageKind.subreddit, sort: sort, identifier: name);

  const FeedPageConfig.user(String username, {FeedSort sort = FeedSort.new_})
      : this(kind: FeedPageKind.user, sort: sort, identifier: username);

  @override
  List<Object?> get props => [kind, sort, identifier];
}

enum FeedPageKind { home, popular, popularAll, saved, search, subreddit, user }

class FeedPageNotifier
    extends CursorPaginatedNotifier<FeedPageState, Feed> {
  final Future<Feed> Function({String? after}) _fetchPage;

  FeedPageNotifier({
    required Future<Feed> Function({String? after}) fetchPage,
    bool autoLoad = true,
  }) : _fetchPage = fetchPage,
       super(const FeedPageState(isLoading: true), autoLoad: autoLoad);

  @override
  Future<Feed> fetchPage({String? after}) => _fetchPage(after: after);

  @override
  String? extractAfter(Feed page) => page.after;

  @override
  FeedPageState buildLoadingState(FeedPageState current) =>
      const FeedPageState(isLoading: true);

  @override
  FeedPageState buildSuccessState(Feed page) => FeedPageState(
        posts: page.posts,
        isLoading: false,
        hasMore: page.hasMorePages,
      );

  @override
  FeedPageState buildLoadingMoreState(FeedPageState current) =>
      FeedPageState(
        posts: current.posts,
        isLoading: false,
        hasMore: current.hasMore,
        isLoadingMore: true,
      );

  @override
  FeedPageState buildAppendedState(FeedPageState current, Feed page) =>
      FeedPageState(
        posts: [...current.posts, ...page.posts],
        isLoading: false,
        hasMore: page.hasMorePages,
      );

  @override
  FeedPageState buildErrorState(String error) =>
      FeedPageState(isLoading: false, error: error);

  @override
  FeedPageState buildErrorWithState(FeedPageState current, String error) =>
      FeedPageState(
        posts: current.posts,
        isLoading: false,
        hasMore: current.hasMore,
        error: error,
      );

  @override
  bool getIsLoadingMore(FeedPageState state) => state.isLoadingMore;

  @override
  bool getHasMore(FeedPageState state) => state.hasMore;
}

Future<Feed> fetchForConfig(
  FeedRepository repo,
  Account? account,
  FeedPageConfig config,
  String? after,
) {
  final cookie = account?.sessionCookie;
  return switch (config.kind) {
    FeedPageKind.home => repo.fetchHome(sort: config.sort, after: after, sessionCookie: cookie),
    FeedPageKind.popular => repo.fetchPopular(after: after, sessionCookie: cookie),
    FeedPageKind.popularAll => repo.fetchPopularAll(sort: config.sort, after: after, sessionCookie: cookie),
    FeedPageKind.saved => repo.fetchSaved(account!.username, after: after, sessionCookie: cookie),
    FeedPageKind.search => repo.search(config.identifier!, after: after, sessionCookie: cookie),
    FeedPageKind.subreddit => repo.fetchSubreddit(config.identifier!, sort: config.sort, after: after, sessionCookie: cookie),
    FeedPageKind.user => repo.fetchUserPosts(config.identifier!, sort: config.sort, after: after, sessionCookie: cookie),
  };
}

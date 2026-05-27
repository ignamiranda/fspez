import 'package:equatable/equatable.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';
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

  const FeedPageConfig.hidden()
      : this(kind: FeedPageKind.hidden, sort: FeedSort.new_);

  const FeedPageConfig.search(String query)
      : this(kind: FeedPageKind.search, sort: FeedSort.new_, identifier: query);

  const FeedPageConfig.subreddit(String name, {FeedSort sort = FeedSort.hot})
      : this(kind: FeedPageKind.subreddit, sort: sort, identifier: name);

  const FeedPageConfig.user(String username, {FeedSort sort = FeedSort.new_})
      : this(kind: FeedPageKind.user, sort: sort, identifier: username);

  @override
  List<Object?> get props => [kind, sort, identifier];
}

enum FeedPageKind { home, popular, popularAll, saved, hidden, search, subreddit, user }

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

String _pathForSort(FeedSort sort) {
  return switch (sort) {
    FeedSort.best => '/best',
    FeedSort.hot => '/hot',
    FeedSort.new_ => '/new',
    FeedSort.top => '/top',
    FeedSort.rising => '/rising',
    FeedSort.controversial => '/controversial',
  };
}

String _popularPathForSort(FeedSort sort) {
  return switch (sort) {
    FeedSort.hot => '/r/popular/hot',
    FeedSort.new_ => '/r/popular/new',
    FeedSort.top => '/r/popular/top',
    FeedSort.rising => '/r/popular/rising',
    FeedSort.controversial => '/r/popular/controversial',
    FeedSort.best => '/r/popular/hot',
  };
}

Future<Feed> _fetchFeed(
  RedditClient client,
  FeedParser parser,
  String path,
  FeedSort sort,
  FeedKind kind,
  String? after, {
  SessionCookie? cookie,
  Map<String, String>? queryOverrides,
}) async {
  final params = <String, String>{
    'sort': sort.label,
    if (after != null) 'after': after,
    'limit': '25',
    'sr_detail': 'true',
    if (queryOverrides != null) ...queryOverrides,
  };
  final data = await client.get(path,
      queryParams: params, sessionCookie: cookie);
  return parser.parseFeed(data, kind, sort);
}

Future<Feed> fetchForConfig(
  Account? account,
  FeedPageConfig config,
  String? after, {
  required RedditClient client,
  required FeedParser parser,
}) {
  final cookie = account?.sessionCookie;
  return switch (config.kind) {
    FeedPageKind.home => _fetchFeed(client, parser, _pathForSort(config.sort), config.sort, FeedKind.home, after, cookie: cookie),
    FeedPageKind.popular => _fetchFeed(client, parser, '/r/popular', FeedSort.hot, FeedKind.popular, after, cookie: cookie),
    FeedPageKind.popularAll => _fetchFeed(client, parser, _popularPathForSort(config.sort), config.sort, FeedKind.popular, after, cookie: cookie),
    FeedPageKind.saved => _fetchFeed(client, parser, '/user/${account!.username}/saved', config.sort, FeedKind.saved, after, cookie: cookie),
    FeedPageKind.hidden => _fetchFeed(client, parser, '/user/${account!.username}/hidden', config.sort, FeedKind.saved, after, cookie: cookie),
    FeedPageKind.search => _fetchFeed(client, parser, '/search', config.sort, FeedKind.popular, after,
        cookie: cookie,
        queryOverrides: {'q': config.identifier!, 'restrict_sr': 'off', 'sort': 'relevance'}),
    FeedPageKind.subreddit => _fetchFeed(client, parser, '/r/${config.identifier!}', config.sort, FeedKind.home, after, cookie: cookie),
    FeedPageKind.user => _fetchFeed(client, parser, '/user/${config.identifier!}/submitted', config.sort, FeedKind.user, after, cookie: cookie),
  };
}

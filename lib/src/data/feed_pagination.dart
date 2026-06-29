import 'package:equatable/equatable.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';
import 'paginated_notifier.dart';
import 'paginated_list_state.dart';

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

  const FeedPageConfig.popular() : this(kind: FeedPageKind.popular);

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

enum FeedPageKind {
  home,
  popular,
  popularAll,
  saved,
  hidden,
  search,
  subreddit,
  user
}

class FeedPageNotifier extends PaginatedNotifier<Post> {
  FeedPageNotifier({
    required super.fetchPage,
    super.autoLoad = true,
  });

  /// Seeds cached items directly into state (skips loading state).
  ///
  /// This is used by [feedPageProvider] on construction when a cached first-page
  /// response is available. The notifier will still perform a background refresh
  /// via [loadInitial] after seeding.
  void seedFromCache(
    Feed feed, {
    required bool isStale,
  }) {
    state = PaginatedListState<Post>(
      items: feed.posts,
      isLoading: false,
      hasMore: feed.hasMorePages,
      isStale: isStale,
    );
    after = feed.after;
  }

  @override
  Future<void> loadInitial() async {
    final previousState = state;
    final previousAfter = after;
    state = previousState.copyWith(isLoading: true, clearError: true);
    after = null;
    try {
      final page = await fetchPage(after: null);
      after = page.after;
      state = PaginatedListState<Post>(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
        isStale: false,
      );
    } catch (e) {
      after = previousAfter;
      if (previousState.items.isNotEmpty) {
        state = previousState.copyWith(isLoading: false, error: e.toString());
      } else {
        state = PaginatedListState<Post>(isLoading: false, error: e.toString());
      }
    }
  }
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
  void Function(Map<String, dynamic> rawData)? onRawResponse,
}) async {
  final params = <String, String>{
    'sort': sort.label,
    if (after != null) 'after': after,
    'limit': '25',
    'sr_detail': 'true',
    if (queryOverrides != null) ...queryOverrides,
  };
  final data =
      await client.get(path, queryParams: params, sessionCookie: cookie);
  if (onRawResponse != null) onRawResponse(data);
  return parser.parseFeed(data, kind, sort);
}

/// Maps a [FeedPageConfig] to the [FeedKind] expected by [FeedParser.parseFeed].
FeedKind feedKindForConfig(FeedPageConfig config) {
  return switch (config.kind) {
    FeedPageKind.home => FeedKind.home,
    FeedPageKind.popular => FeedKind.popular,
    FeedPageKind.popularAll => FeedKind.popular,
    FeedPageKind.saved => FeedKind.saved,
    FeedPageKind.hidden => FeedKind.saved,
    FeedPageKind.search => FeedKind.popular,
    FeedPageKind.subreddit => FeedKind.home,
    FeedPageKind.user => FeedKind.user,
  };
}

Future<Feed> fetchForConfig(
  Account? account,
  FeedPageConfig config,
  String? after, {
  required RedditClient client,
  required FeedParser parser,
  void Function(Map<String, dynamic> rawData)? onRawResponse,
}) {
  final cookie = account?.sessionCookie;
  return switch (config.kind) {
    FeedPageKind.home => _fetchFeed(client, parser, _pathForSort(config.sort),
        config.sort, FeedKind.home, after,
        cookie: cookie, onRawResponse: onRawResponse),
    FeedPageKind.popular => _fetchFeed(
        client, parser, '/r/popular', FeedSort.hot, FeedKind.popular, after,
        cookie: cookie, onRawResponse: onRawResponse),
    FeedPageKind.popularAll => _fetchFeed(client, parser,
        _popularPathForSort(config.sort), config.sort, FeedKind.popular, after,
        cookie: cookie, onRawResponse: onRawResponse),
    FeedPageKind.saved => _fetchFeed(client, parser,
        '/user/${account!.username}/saved', config.sort, FeedKind.saved, after,
        cookie: cookie, onRawResponse: onRawResponse),
    FeedPageKind.hidden => _fetchFeed(client, parser,
        '/user/${account!.username}/hidden', config.sort, FeedKind.saved, after,
        cookie: cookie, onRawResponse: onRawResponse),
    FeedPageKind.search => _fetchFeed(
          client, parser, '/search', config.sort, FeedKind.popular, after,
          cookie: cookie,
          onRawResponse: onRawResponse,
          queryOverrides: {
            'q': config.identifier!,
            'restrict_sr': 'off',
            'sort': 'relevance'
          }),
    FeedPageKind.subreddit => _fetchFeed(client, parser,
        '/r/${config.identifier!}', config.sort, FeedKind.home, after,
        cookie: cookie, onRawResponse: onRawResponse),
    FeedPageKind.user => _fetchFeed(
        client,
        parser,
        '/user/${config.identifier!}/submitted',
        config.sort,
        FeedKind.user,
        after,
        cookie: cookie,
        onRawResponse: onRawResponse),
  };
}

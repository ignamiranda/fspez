import 'package:equatable/equatable.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import '../domain/enums/top_time_filter.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';
import 'paginated_notifier.dart';
import 'paginated_list_state.dart';

class FeedPageConfig with Equatable {
  final FeedPageKind kind;
  final FeedSort sort;
  final String? identifier;
  final TopTimeFilter topTimeFilter;

  const FeedPageConfig({
    required this.kind,
    this.sort = FeedSort.hot,
    this.identifier,
    this.topTimeFilter = TopTimeFilter.all,
  });

  const FeedPageConfig.home({
    FeedSort sort = FeedSort.hot,
    TopTimeFilter topTimeFilter = TopTimeFilter.all,
  }) : this(kind: FeedPageKind.home, sort: sort, topTimeFilter: topTimeFilter);

  const FeedPageConfig.popular() : this(kind: FeedPageKind.popular);

  const FeedPageConfig.popularAll({
    FeedSort sort = FeedSort.hot,
    TopTimeFilter topTimeFilter = TopTimeFilter.all,
  }) : this(
            kind: FeedPageKind.popularAll,
            sort: sort,
            topTimeFilter: topTimeFilter);

  const FeedPageConfig.saved()
      : this(kind: FeedPageKind.saved, sort: FeedSort.new_);

  const FeedPageConfig.hidden()
      : this(kind: FeedPageKind.hidden, sort: FeedSort.new_);

  const FeedPageConfig.search(String query)
      : this(kind: FeedPageKind.search, sort: FeedSort.new_, identifier: query);

  const FeedPageConfig.subreddit(
    String name, {
    FeedSort sort = FeedSort.hot,
    TopTimeFilter topTimeFilter = TopTimeFilter.all,
  }) : this(
            kind: FeedPageKind.subreddit,
            sort: sort,
            identifier: name,
            topTimeFilter: topTimeFilter);

  const FeedPageConfig.user(
    String username, {
    FeedSort sort = FeedSort.new_,
    TopTimeFilter topTimeFilter = TopTimeFilter.all,
  }) : this(
            kind: FeedPageKind.user,
            sort: sort,
            identifier: username,
            topTimeFilter: topTimeFilter);

  @override
  List<Object?> get props => [kind, sort, identifier, topTimeFilter];
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
  // ignore: use_super_parameters
  FeedPageNotifier({
    required Future<PaginatedResult<Post>> Function({String? after}) fetchPage,
    bool autoLoad = true,
  }) : super(
          fetchPage: fetchPage,
          autoLoad: autoLoad,
          onLoadError: (prev, error) {
            if (prev.items.isNotEmpty) {
              return prev.copyWith(isLoading: false, error: error.toString());
            }
            return PaginatedListState<Post>(
              isLoading: false,
              error: error.toString(),
            );
          },
        );

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
  TopTimeFilter? topTimeFilter,
}) async {
  final params = <String, String>{
    'sort': sort.label,
    if (after != null) 'after': after,
    'limit': '25',
    'sr_detail': 'true',
    if (sort == FeedSort.top && topTimeFilter != null)
      't': topTimeFilter.queryValue,
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
  final ttf = config.topTimeFilter;
  return switch (config.kind) {
    FeedPageKind.home => _fetchFeed(client, parser, _pathForSort(config.sort),
        config.sort, FeedKind.home, after,
        cookie: cookie, onRawResponse: onRawResponse, topTimeFilter: ttf),
    FeedPageKind.popular => _fetchFeed(
        client, parser, '/r/popular', FeedSort.hot, FeedKind.popular, after,
        cookie: cookie, onRawResponse: onRawResponse, topTimeFilter: ttf),
    FeedPageKind.popularAll => _fetchFeed(client, parser,
        _popularPathForSort(config.sort), config.sort, FeedKind.popular, after,
        cookie: cookie, onRawResponse: onRawResponse, topTimeFilter: ttf),
    FeedPageKind.saved => _fetchFeed(client, parser,
        '/user/${account!.username}/saved', config.sort, FeedKind.saved, after,
        cookie: cookie, onRawResponse: onRawResponse, topTimeFilter: ttf),
    FeedPageKind.hidden => _fetchFeed(client, parser,
        '/user/${account!.username}/hidden', config.sort, FeedKind.saved, after,
        cookie: cookie, onRawResponse: onRawResponse, topTimeFilter: ttf),
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
        cookie: cookie, onRawResponse: onRawResponse, topTimeFilter: ttf),
    FeedPageKind.user => _fetchFeed(
        client,
        parser,
        '/user/${config.identifier!}/submitted',
        config.sort,
        FeedKind.user,
        after,
        cookie: cookie,
        onRawResponse: onRawResponse,
        topTimeFilter: ttf),
  };
}

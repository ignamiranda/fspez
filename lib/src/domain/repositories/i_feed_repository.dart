import '../enums/feed_sort.dart';
import '../models/feed.dart';
import '../models/session_cookie.dart';

abstract class IFeedRepository {
  Future<Feed> fetchFeed({
    required FeedPageKind kind,
    FeedSort sort = FeedSort.hot,
    String? identifier,
    String? after,
    SessionCookie? sessionCookie,
  });
}

enum FeedPageKind {
  home,
  popular,
  popularAll,
  saved,
  hidden,
  search,
  subreddit,
  user,
}

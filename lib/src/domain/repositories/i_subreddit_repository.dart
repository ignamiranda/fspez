import '../models/subreddit.dart';
import '../models/subreddit_rule.dart';
import '../models/session_cookie.dart';

abstract class ISubredditRepository {
  Future<Subreddit> fetch(String subredditName, {SessionCookie? sessionCookie});

  Future<List<SubredditRule>> fetchRules(
    String subredditName, {
    SessionCookie? sessionCookie,
  });

  Future<void> subscribe(String subredditName, {SessionCookie? sessionCookie});

  Future<void> unsubscribe(
    String subredditName, {
    SessionCookie? sessionCookie,
  });
}

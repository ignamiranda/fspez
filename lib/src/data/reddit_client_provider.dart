import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reddit_client.dart';

final redditClientProvider = Provider<RedditClient>((ref) {
  final client = RedditClient();
  ref.onDispose(() => client.dispose());
  return client;
});

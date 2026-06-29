import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'http_transport.dart';
import 'reddit_client.dart';

final httpTransportProvider = Provider<HttpTransport>((ref) {
  return HttpTransport();
});

final redditClientProvider = Provider<RedditClient>((ref) {
  final client = RedditClient(transport: ref.watch(httpTransportProvider));
  ref.onDispose(() => client.dispose());
  return client;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'feed_cache.dart';

final feedCacheProvider = Provider<FeedCache>((ref) {
  return FeedCache(ref.watch(sharedPrefsProvider));
});

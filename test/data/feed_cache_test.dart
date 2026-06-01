import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fspez/src/data/feed_cache.dart';
import 'package:fspez/src/data/feed_pagination.dart';
import 'package:fspez/src/domain/enums/feed_sort.dart';

void main() {
  late FeedCache cache;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = FeedCache(prefs);
  });

  group('FeedCache key isolation', () {
    test('different account IDs produce different cache entries', () {
      const config = FeedPageConfig.home();
      cache.set('alice', config, {'data': {}});
      cache.set('bob', config, {
        'data': {'x': 1},
      });

      final aliceEntry = cache.get('alice', config);
      final bobEntry = cache.get('bob', config);

      expect(aliceEntry?.data, {'data': {}});
      expect(bobEntry?.data, {
        'data': {'x': 1},
      });
    });

    test('anon account falls through to its own cache key', () {
      const config = FeedPageConfig.popular();
      cache.set('anon', config, {'data': {}});

      final entry = cache.get('anon', config);
      expect(entry, isNotNull);
      expect(entry!.data, {'data': {}});
    });

    test('different configs produce different cache entries', () {
      const homeConfig = FeedPageConfig.home();
      const popularConfig = FeedPageConfig.popular();

      cache.set('anon', homeConfig, {'data': 'home'});
      cache.set('anon', popularConfig, {'data': 'popular'});

      expect(cache.get('anon', homeConfig)?.data, {'data': 'home'});
      expect(cache.get('anon', popularConfig)?.data, {'data': 'popular'});
    });

    test('same config with different sort are isolated', () {
      const hotConfig = FeedPageConfig.home(sort: FeedSort.hot);
      const newConfig = FeedPageConfig.home(sort: FeedSort.new_);

      cache.set('anon', hotConfig, {'data': 'hot'});
      cache.set('anon', newConfig, {'data': 'new'});

      expect(cache.get('anon', hotConfig)?.data, {'data': 'hot'});
      expect(cache.get('anon', newConfig)?.data, {'data': 'new'});
    });

    test('subreddit configs differ by name', () {
      final flutterConfig = FeedPageConfig.subreddit('flutter');
      final dartConfig = FeedPageConfig.subreddit('dart');

      cache.set('anon', flutterConfig, {'data': 'flutter'});
      cache.set('anon', dartConfig, {'data': 'dart'});

      expect(cache.get('anon', flutterConfig)?.data, {'data': 'flutter'});
      expect(cache.get('anon', dartConfig)?.data, {'data': 'dart'});
    });
  });

  group('FeedCache round-trip', () {
    test('set and get returns same JSON', () {
      const config = FeedPageConfig.home();
      const json = {
        'data': {
          'children': [],
          'after': null,
        },
      };

      cache.set('anon', config, json);
      final entry = cache.get('anon', config);

      expect(entry, isNotNull);
      expect(entry!.data, json);
      expect(entry.cachedAt, isNotNull);
    });

    test('cache miss returns null', () {
      const config = FeedPageConfig.home();
      final entry = cache.get('missing', config);
      expect(entry, isNull);
    });

    test('remove deletes entry', () {
      const config = FeedPageConfig.home();
      cache.set('anon', config, {'data': {}});
      cache.remove('anon', config);

      expect(cache.get('anon', config), isNull);
    });

    test('clearForAccount removes all entries for that account', () {
      cache.set('alice', const FeedPageConfig.home(), {'data': {}});
      cache.set('alice', const FeedPageConfig.popular(), {'data': {}});
      cache.set('bob', const FeedPageConfig.home(), {'data': {}});

      cache.clearForAccount('alice');

      expect(cache.get('alice', const FeedPageConfig.home()), isNull);
      expect(cache.get('alice', const FeedPageConfig.popular()), isNull);
      expect(cache.get('bob', const FeedPageConfig.home()), isNotNull);
    });
  });

  group('FeedCache staleness metadata', () {
    test('cachedAt is set on write', () {
      const config = FeedPageConfig.home();

      cache.set('anon', config, {'data': {}});
      final entry = cache.get('anon', config);

      expect(entry, isNotNull);
      expect(entry!.cachedAt, isNotNull);
      expect(
        DateTime.now().difference(entry.cachedAt).inSeconds.abs(),
        lessThan(10),
      );
    });

    test('cachedAt updates on subsequent writes', () async {
      const config = FeedPageConfig.home();
      cache.set('anon', config, {'data': {}});
      final firstEntry = cache.get('anon', config);
      final firstTs = firstEntry!.cachedAt;

      await Future.delayed(const Duration(milliseconds: 2));

      cache.set('anon', config, {'updated': true});
      final secondEntry = cache.get('anon', config);
      final secondTs = secondEntry!.cachedAt;

      expect(secondTs.isAfter(firstTs), isTrue);
      expect(secondEntry.data, {'updated': true});
    });
  });
}

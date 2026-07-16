import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/feed_pagination.dart';
import 'package:fspez/src/domain/models/paginated_result.dart';

import 'package:fspez/src/domain/models/feed.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/models/subreddit.dart';
import 'package:fspez/src/domain/enums/feed_sort.dart';

Post _post(String id) {
  return Post(
    id: id,
    title: 'Post $id',
    author: 'user',
    subreddit: const Subreddit(id: '', name: 'test'),
    createdAt: DateTime.now(),
    permalink: '/r/test/$id',
    type: PostType.link,
  );
}

Feed _feed({required List<Post> posts, String? after}) {
  return Feed(
    kind: FeedKind.home,
    sort: FeedSort.hot,
    posts: posts,
    after: after,
  );
}

void main() {
  group('FeedPageNotifier', () {
    test('initial state has isLoading true', () {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(const PaginatedResult<Post>(
          items: [],
        )),
        autoLoad: false,
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.items, isEmpty);
    });

    test('loadInitial sets isLoading false and populates items after success',
        () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(PaginatedResult<Post>(
          items: [_post('1'), _post('2')],
          after: 't3_cursor',
          hasMore: true,
        )),
        autoLoad: false,
      );

      await notifier.loadInitial();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.items.length, 2);
      expect(notifier.state.items[0].id, '1');
      expect(notifier.state.items[1].id, '2');
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.error, isNull);
    });

    test(
        'loadInitial sets isLoading false and hasMore false when after is null',
        () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(PaginatedResult<Post>(
          items: [_post('1')],
        )),
        autoLoad: false,
      );

      await notifier.loadInitial();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasMore, isFalse);
    });

    test('loadInitial sets isLoading false and error on failure', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.error(Exception('API error')),
        autoLoad: false,
      );

      await notifier.loadInitial();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.items, isEmpty);
    });

    test('loadMore appends items and updates cursor', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) {
          return Future.value(PaginatedResult<Post>(
            items: after == null ? [_post('1')] : [_post('2')],
            after: after == null ? 'cursor1' : null,
            hasMore: after == null,
          ));
        },
        autoLoad: false,
      );

      await notifier.loadInitial();
      expect(notifier.state.items.length, 1);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();
      expect(notifier.state.items.length, 2);
      expect(notifier.state.items[1].id, '2');
      expect(notifier.state.hasMore, isFalse);
    });

    test('loadMore is no-op when hasMore is false', () async {
      var callCount = 0;
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) {
          callCount++;
          return Future.value(PaginatedResult<Post>(
            items: [_post('1')],
          ));
        },
        autoLoad: false,
      );

      await notifier.loadInitial();
      expect(callCount, 1);

      await notifier.loadMore();
      expect(callCount, 1);
    });

    test('loadMore is no-op when already loading more', () async {
      var callCount = 0;
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return PaginatedResult<Post>(
            items: [_post('1')],
            after: 'cursor',
            hasMore: true,
          );
        },
        autoLoad: false,
      );

      await notifier.loadInitial();
      final initialCount = callCount;

      notifier.loadMore();
      notifier.loadMore();
      notifier.loadMore();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callCount, initialCount + 1);
    });

    test('loadMore preserves existing items on error', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) async {
          if (after == null) {
            return PaginatedResult<Post>(
              items: [_post('1')],
              after: 'cursor',
              hasMore: true,
            );
          }
          throw Exception('Load more failed');
        },
        autoLoad: false,
      );

      await notifier.loadInitial();
      expect(notifier.state.items.length, 1);

      await notifier.loadMore();

      expect(notifier.state.items.length, 1);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.items[0].id, '1');
    });
  });

  group('FeedPageConfig equality', () {
    test('popular and home are different keys', () {
      expect(
        const FeedPageConfig.popular(),
        isNot(const FeedPageConfig.home()),
      );
    });

    test('same configs are equal', () {
      expect(
        const FeedPageConfig.home(),
        equals(const FeedPageConfig.home()),
      );
    });

    test('same config with different sort are different', () {
      expect(
        const FeedPageConfig.home(),
        isNot(const FeedPageConfig.home(sort: FeedSort.new_)),
      );
    });

    test('subreddit configs differ by name', () {
      expect(
        const FeedPageConfig.subreddit('flutter'),
        isNot(const FeedPageConfig.subreddit('dart')),
      );
    });

    test('search configs differ by query', () {
      expect(
        const FeedPageConfig.search('foo'),
        isNot(const FeedPageConfig.search('bar')),
      );
    });

    test('user configs differ by username', () {
      expect(
        const FeedPageConfig.user('alice'),
        isNot(const FeedPageConfig.user('bob')),
      );
    });

    test('user config equals same username', () {
      expect(
        const FeedPageConfig.user('alice'),
        equals(const FeedPageConfig.user('alice')),
      );
    });
  });

  group('FeedPageNotifier cache seeding', () {
    test('seedFromCache populates state and sets isStale', () {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(const PaginatedResult<Post>(
          items: [],
        )),
        autoLoad: false,
      );

      notifier.seedFromCache(
        _feed(posts: [_post('1'), _post('2')], after: 'cursor'),
        isStale: true,
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.items.length, 2);
      expect(notifier.state.isStale, isTrue);
      expect(notifier.state.error, isNull);
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.after, 'cursor');
    });

    test('seedFromCache with isStale:false does not mark content as stale', () {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(const PaginatedResult<Post>(
          items: [],
        )),
        autoLoad: false,
      );

      notifier.seedFromCache(_feed(posts: [_post('1')]), isStale: false);

      expect(notifier.state.isStale, isFalse);
    });

    test('loadInitial with cached items preserves them on failure', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.error(Exception('Refresh failed')),
        autoLoad: false,
      );

      notifier.seedFromCache(_feed(posts: [_post('1')], after: 'cursor1'),
          isStale: true);
      await notifier.loadInitial();

      // Cached items should be preserved on error.
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items[0].id, '1');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.isStale, isTrue);
      expect(notifier.after, 'cursor1');
    });

    test('loadInitial with cached items replaces them on success', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(PaginatedResult<Post>(
          items: [_post('fresh')],
        )),
        autoLoad: false,
      );

      notifier.seedFromCache(_feed(posts: [_post('stale')]), isStale: true);
      await notifier.loadInitial();

      // Fresh items replace cached items.
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items[0].id, 'fresh');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadInitial seeding then success clears isStale', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(PaginatedResult<Post>(
          items: [_post('fresh')],
        )),
        autoLoad: false,
      );

      notifier.seedFromCache(_feed(posts: [_post('stale')]), isStale: true);
      await notifier.loadInitial();

      expect(notifier.state.isStale, isFalse);
    });

    test('refresh preserves items from previous load on failure', () async {
      var shouldFail = false;
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) async {
          if (shouldFail) {
            throw Exception('Refresh failed');
          }
          return PaginatedResult<Post>(
            items: [_post('1')],
          );
        },
        autoLoad: false,
      );

      // Initial success load.
      await notifier.loadInitial();
      expect(notifier.state.items.length, 1);

      // Now make the next refresh fail.
      shouldFail = true;

      await notifier.refresh();

      // Previous items should be preserved.
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items[0].id, '1');
      expect(notifier.state.error, isNotNull);
    });

    test('loadInitial without cached items still blanks on error', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.error(Exception('API error')),
        autoLoad: false,
      );

      await notifier.loadInitial();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.items, isEmpty);
    });
  });
}

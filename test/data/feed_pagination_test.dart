import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/feed_pagination.dart';
import 'package:fspez/src/domain/models/feed.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/models/subreddit.dart';
import 'package:fspez/src/domain/enums/feed_sort.dart';

Post _post(String id) {
  return Post(
    id: id,
    title: 'Post $id',
    author: 'user',
    subreddit: Subreddit(id: '', name: 'test'),
    createdAt: DateTime.now(),
    permalink: '/r/test/$id',
    type: PostType.link,
  );
}

void main() {
  group('FeedPageNotifier', () {
    test('initial state has isLoading true', () {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(Feed(
          kind: FeedKind.home, sort: FeedSort.hot,
        )),
        autoLoad: false,
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.posts, isEmpty);
    });

    test('loadInitial sets isLoading false and populates posts after success', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(Feed(
          kind: FeedKind.home,
          sort: FeedSort.hot,
          posts: [_post('1'), _post('2')],
          after: 't3_cursor',
        )),
        autoLoad: false,
      );

      await notifier.loadInitial();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.posts.length, 2);
      expect(notifier.state.posts[0].id, '1');
      expect(notifier.state.posts[1].id, '2');
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('loadInitial sets isLoading false and hasMore false when after is null', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) => Future.value(Feed(
          kind: FeedKind.home, sort: FeedSort.hot,
          posts: [_post('1')],
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
      expect(notifier.state.posts, isEmpty);
    });

    test('loadMore appends posts and updates cursor', () async {
      var callCount = 0;
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) {
          callCount++;
          return Future.value(Feed(
            kind: FeedKind.home, sort: FeedSort.hot,
            posts: after == null ? [_post('1')] : [_post('2')],
            after: after == null ? 'cursor1' : null,
          ));
        },
        autoLoad: false,
      );

      await notifier.loadInitial();
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();
      expect(notifier.state.posts.length, 2);
      expect(notifier.state.posts[1].id, '2');
      expect(notifier.state.hasMore, isFalse);
    });

    test('loadMore is no-op when hasMore is false', () async {
      var callCount = 0;
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) {
          callCount++;
          return Future.value(Feed(
            kind: FeedKind.home, sort: FeedSort.hot,
            posts: [_post('1')],
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
          return Feed(
            kind: FeedKind.home, sort: FeedSort.hot,
            posts: [_post('1')],
            after: 'cursor',
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

    test('loadMore preserves existing posts on error', () async {
      final notifier = FeedPageNotifier(
        fetchPage: ({after}) async {
          if (after == null) {
            return Feed(
              kind: FeedKind.home, sort: FeedSort.hot,
              posts: [_post('1')],
              after: 'cursor',
            );
          }
          throw Exception('Load more failed');
        },
        autoLoad: false,
      );

      await notifier.loadInitial();
      expect(notifier.state.posts.length, 1);

      await notifier.loadMore();

      expect(notifier.state.posts.length, 1);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.posts[0].id, '1');
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
        isNot(FeedPageConfig.home(sort: FeedSort.new_)),
      );
    });

    test('subreddit configs differ by name', () {
      expect(
        FeedPageConfig.subreddit('flutter'),
        isNot(FeedPageConfig.subreddit('dart')),
      );
    });

    test('search configs differ by query', () {
      expect(
        FeedPageConfig.search('foo'),
        isNot(FeedPageConfig.search('bar')),
      );
    });
  });
}
